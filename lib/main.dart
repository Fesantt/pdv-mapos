import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
 await initializeDateFormatting('pt_BR', null);
 runApp(const MyApp());
}

class MyApp extends StatelessWidget {
 const MyApp({super.key});

 @override
 Widget build(BuildContext context) {
  return MaterialApp(
   title: 'PDV - LOJA ANDRADE SEI LÁ DO QUE',
   theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
     seedColor: const Color(0xFF6366F1),
     brightness: Brightness.light,
    ),
    useMaterial3: true,
    fontFamily: 'SF Pro Display',
    elevatedButtonTheme: ElevatedButtonThemeData(
     style: ElevatedButton.styleFrom(
      elevation: 0,
      shape: RoundedRectangleBorder(
       borderRadius: BorderRadius.circular(16),
      ),
     ),
    ),
   ),
   home: const LoginScreen(),
   debugShowCheckedModeBanner: false,
  );
 }
}

class ApiProduct {
 final String id;
 final String codDeBarra;
 final String descricao;
 final String unidade;
 final double precoCompra;
 final double precoVenda;
 final int estoque;
 final int estoqueMinimo;

 ApiProduct({
  required this.id,
  required this.codDeBarra,
  required this.descricao,
  required this.unidade,
  required this.precoCompra,
  required this.precoVenda,
  required this.estoque,
  required this.estoqueMinimo,
 });

 factory ApiProduct.fromJson(Map<String, dynamic> json) {
  return ApiProduct(
   id: json['idProdutos'].toString(),
   codDeBarra: json['codDeBarra'],
   descricao: json['descricao'],
   unidade: json['unidade'],
   precoCompra: double.parse(json['precoCompra'].toString()),
   precoVenda: double.parse(json['precoVenda'].toString()),
   estoque: int.parse(json['estoque'].toString()),
   estoqueMinimo: int.parse(json['estoqueMinimo'].toString()),
  );
 }
}

class User {
 final String id;
 final String nome;
 final String email;
 final String codigoPdv;

 User({
  required this.id,
  required this.nome,
  required this.email,
  required this.codigoPdv,
 });

 factory User.fromJson(Map<String, dynamic> json) {
  return User(
   id: json['idUsuarios'],
   nome: json['nome'],
   email: json['email'],
   codigoPdv: json['codigo_pdv'],
  );
 }
}

class ApiClient {
 final String id;
 final String nomeCliente;
 final String documento;
 final String telefone;
 final String celular;
 final String email;
 final String endereco;
 final bool isPessoaFisica;

 ApiClient({
  required this.id,
  required this.nomeCliente,
  required this.documento,
  required this.telefone,
  required this.celular,
  required this.email,
  required this.endereco,
  required this.isPessoaFisica,
 });

 factory ApiClient.fromJson(Map<String, dynamic> json) {
  final endereco = '${json['rua']}, ${json['numero']}${json['complemento'].toString().isNotEmpty ? ', ${json['complemento']}' : ''} - ${json['bairro']}, ${json['cidade']}/${json['estado']} - ${json['cep']}';

  return ApiClient(
   id: json['idClientes'].toString(),
   nomeCliente: json['nomeCliente'],
   documento: json['documento'],
   telefone: json['telefone'] ?? '',
   celular: json['celular'] ?? '',
   email: json['email'] ?? '',
   endereco: endereco,
   isPessoaFisica: json['pessoa_fisica'] == '1',
  );
 }
}

class PdvApiService {
 static const String baseUrl = 'https://pdv.evs.lat/index.php/pdv';
 String? _authToken;

 Future<User?> login(String codigoPdv) async {
  try {
   final response = await http.post(
    Uri.parse('$baseUrl/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'codigo_pdv': codigoPdv}),
   );

   if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success']) {
     _authToken = codigoPdv;
     return User.fromJson(data['data']);
    }
   }
  } catch (e) {
   print('Erro no login: $e');
  }
  return null;
 }

 Future<List<ApiProduct>> getProducts() async {
  try {
   final response = await http.get(
    Uri.parse(baseUrl),
    headers: {
     'Content-Type': 'application/json',
     'Authorization': _authToken ?? '',
    },
   );

   if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success']) {
     return (data['data'] as List)
         .map((json) => ApiProduct.fromJson(json))
         .toList();
    }
   }
  } catch (e) {
   print('Erro ao carregar produtos: $e');
  }
  return [];
 }

 Future<List<ApiClient>> getClients() async {
  try {
   final response = await http.get(
    Uri.parse('$baseUrl/clientes'),
    headers: {
     'Content-Type': 'application/json',
     'Authorization': _authToken ?? '',
    },
   );

   if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success']) {
     return (data['data'] as List)
         .map((json) => ApiClient.fromJson(json))
         .toList();
    }
   }
  } catch (e) {
   print('Erro ao carregar clientes: $e');
  }
  return [];
 }

 Future<Map<String, dynamic>?> createSale(
     List<Map<String, dynamic>> produtos, {
      String? clienteId,
     }) async {
  try {
   final Map<String, dynamic> saleData = {
    'produtos': produtos.map((item) => {
     'idProdutos': int.parse(item['id'].toString()),
     'quantidade': item['quantity'],
    }).toList(),
   };

   if (clienteId != null && clienteId.isNotEmpty) {
    saleData['clientes_id'] = int.parse(clienteId);
   }

   final response = await http.post(
    Uri.parse('$baseUrl/criarVenda'),
    headers: {
     'Content-Type': 'application/json',
     'Authorization': _authToken ?? '',
    },
    body: jsonEncode(saleData),
   );

   if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success']) {
     return data;
    }
   }
  } catch (e) {
   print('Erro ao criar venda: $e');
  }
  return null;
 }
}

class LoginScreen extends StatefulWidget {
 const LoginScreen({super.key});

 @override
 State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
 final TextEditingController _codeController = TextEditingController();
 final PdvApiService _apiService = PdvApiService();
 bool _isLoading = false;

 Future<void> _login() async {
  if (_codeController.text.isEmpty) {
   _showErrorSnackBar('Digite o código do PDV');
   return;
  }

  setState(() => _isLoading = true);

  final user = await _apiService.login(_codeController.text);

  setState(() => _isLoading = false);

  if (user != null) {
   Navigator.of(context).pushReplacement(
    MaterialPageRoute(
     builder: (context) => PdvScreen(user: user, apiService: _apiService),
    ),
   );
  } else {
   _showErrorSnackBar('Código inválido');
  }
 }

 void _showErrorSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
   SnackBar(
    content: Text(message),
    backgroundColor: Colors.red,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
   ),
  );
 }

 @override
 Widget build(BuildContext context) {
  return Scaffold(
   backgroundColor: const Color(0xFFF8FAFC),
   body: Center(
    child: Container(
     width: 400,
     padding: const EdgeInsets.all(32),
     decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
       BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 20,
        offset: const Offset(0, 8),
       ),
      ],
     ),
     child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
       Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
         gradient: const LinearGradient(
          colors: [Color(0xFFE44D0F), Color(0xFFFF5900)],
         ),
         borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
         Icons.storefront,
         color: Colors.white,
         size: 40,
        ),
       ),
       const SizedBox(height: 24),
       const Text(
        'LOJA ANDRADE',
        style: TextStyle(
         fontSize: 28,
         fontWeight: FontWeight.bold,
         color: Color(0xFF1F2937),
        ),
       ),
       const Text(
        'Sistema de Ponto de Venda',
        style: TextStyle(
         fontSize: 16,
         color: Color(0xFF64748B),
        ),
       ),
       const SizedBox(height: 32),
       TextField(
        controller: _codeController,
        decoration: InputDecoration(
         labelText: 'Código do PDV',
         hintText: 'Digite o código de acesso',
         prefixIcon: const Icon(Icons.vpn_key),
         border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
         ),
        ),
        onSubmitted: (_) => _login(),
       ),
       const SizedBox(height: 24),
       SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
         onPressed: _isLoading ? null : _login,
         style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF5900),
          shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(12),
          ),
         ),
         child: _isLoading
             ? const CircularProgressIndicator(color: Colors.white)
             : const Text(
          'Entrar',
          style: TextStyle(
           color: Colors.white,
           fontSize: 16,
           fontWeight: FontWeight.bold,
          ),
         ),
        ),
       ),
      ],
     ),
    ),
   ),
  );
 }
}

class PdvScreen extends StatefulWidget {
 final User user;
 final PdvApiService apiService;

 const PdvScreen({
  super.key,
  required this.user,
  required this.apiService,
 });

 @override
 State<PdvScreen> createState() => _PdvScreenState();
}

class _PdvScreenState extends State<PdvScreen> with TickerProviderStateMixin {
 late AnimationController _animationController;
 late Animation<double> _fadeAnimation;

 final NumberFormat _currencyFormat = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
 );

 List<ApiProduct> _allProducts = [];
 List<ApiProduct> _foundProducts = [];
 List<ApiClient> _allClients = [];
 List<Map<String, dynamic>> _cartItems = [];
 ApiClient? _selectedCustomer;
 bool _isCashSale = true;
 double _discountPercentage = 0.0;
 double _discountValue = 0.0;
 bool _isLoading = true;

 final TextEditingController _searchController = TextEditingController();
 final TextEditingController _discountPercentController = TextEditingController();
 final TextEditingController _discountValueController = TextEditingController();

 @override
 void initState() {
  super.initState();
  _animationController = AnimationController(
   duration: const Duration(milliseconds: 300),
   vsync: this,
  );
  _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
   CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
  );
  _animationController.forward();
  _loadProducts();
 }

 Future<void> _loadProducts() async {
  final products = await widget.apiService.getProducts();
  final clients = await widget.apiService.getClients();
  setState(() {
   _allProducts = products;
   _foundProducts = products;
   _allClients = clients;
   _isLoading = false;
  });
 }

 @override
 void dispose() {
  _animationController.dispose();
  _searchController.dispose();
  _discountPercentController.dispose();
  _discountValueController.dispose();
  super.dispose();
 }

 void _filterProducts(String enteredKeyword) {
  List<ApiProduct> results = [];
  if (enteredKeyword.isEmpty) {
   results = _allProducts;
  } else {
   results = _allProducts
       .where((product) =>
   product.descricao.toLowerCase().contains(enteredKeyword.toLowerCase()) ||
       product.codDeBarra.toLowerCase().contains(enteredKeyword.toLowerCase()))
       .toList();
  }
  setState(() {
   _foundProducts = results;
  });
 }

 void _addToCart(ApiProduct product) {
  setState(() {
   final existingItemIndex = _cartItems.indexWhere(
        (item) => item['id'] == product.id,
   );

   if (existingItemIndex != -1) {
    _cartItems[existingItemIndex]['quantity']++;
   } else {
    _cartItems.add({
     'id': product.id,
     'name': product.descricao,
     'price': product.precoVenda,
     'code': product.codDeBarra,
     'quantity': 1,
    });
   }
  });

  HapticFeedback.lightImpact();
  ScaffoldMessenger.of(context).showSnackBar(
   SnackBar(
    content: Row(
     children: [
      const Icon(Icons.check_circle, color: Colors.white, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Text('${product.descricao} adicionado')),
     ],
    ),
    duration: const Duration(seconds: 1),
    backgroundColor: const Color(0xFF10B981),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(16),
   ),
  );
 }

 void _updateQuantity(int index, int newQuantity) {
  setState(() {
   if (newQuantity <= 0) {
    _cartItems.removeAt(index);
   } else {
    _cartItems[index]['quantity'] = newQuantity;
   }
  });
 }

 void _removeFromCart(int index) {
  setState(() {
   _cartItems.removeAt(index);
  });
 }

 double get _subtotal {
  return _cartItems.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
 }

 double get _totalDiscount {
  double percentDiscount = _subtotal * (_discountPercentage / 100);
  return percentDiscount + _discountValue;
 }

 double get _finalTotal {
  return _subtotal - _totalDiscount;
 }

 void _applyPercentageDiscount(String value) {
  setState(() {
   _discountPercentage = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
   if (_discountPercentage > 100) _discountPercentage = 100;
   if (_discountPercentage < 0) _discountPercentage = 0;
  });
 }

 void _applyValueDiscount(String value) {
  setState(() {
   _discountValue = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
   if (_discountValue > _subtotal) _discountValue = _subtotal;
   if (_discountValue < 0) _discountValue = 0;
  });
 }

 void _clearCart() {
  setState(() {
   _cartItems.clear();
   _discountPercentage = 0.0;
   _discountValue = 0.0;
   _discountPercentController.clear();
   _discountValueController.clear();
   _selectedCustomer = null;
   _isCashSale = true;
  });
 }

 Future<void> _finalizeSale() async {
  if (_cartItems.isEmpty) {
   ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
     content: const Row(
      children: [
       Icon(Icons.warning, color: Colors.white),
       SizedBox(width: 12),
       Text('Carrinho vazio! Adicione produtos para continuar.'),
      ],
     ),
     backgroundColor: Colors.orange,
     behavior: SnackBarBehavior.floating,
     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
     margin: const EdgeInsets.all(16),
    ),
   );
   return;
  }

  showDialog(
   context: context,
   barrierDismissible: false,
   builder: (context) => const Center(
    child: CircularProgressIndicator(),
   ),
  );

  try {
   final result = await widget.apiService.createSale(
    _cartItems,
    clienteId: _selectedCustomer?.id,
   );

   Navigator.of(context).pop();

   if (result != null) {
    _showSuccessDialog(result);
    _clearCart();
   } else {
    _showErrorSnackBar('Erro ao finalizar venda');
   }
  } catch (e) {
   Navigator.of(context).pop();
   _showErrorSnackBar('Erro: $e');
  }
 }

 void _showSuccessDialog(Map<String, dynamic> saleResult) {
  showDialog(
   context: context,
   builder: (context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Container(
     padding: const EdgeInsets.all(24),
     child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
       const Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 64,
       ),
       const SizedBox(height: 16),
       const Text(
        'Venda Finalizada!',
        style: TextStyle(
         fontSize: 24,
         fontWeight: FontWeight.bold,
        ),
       ),
       const SizedBox(height: 16),
       Text('Venda ID: ${saleResult['idVendas']}'),
       Text('Total: ${_currencyFormat.format(saleResult['valorTotal'])}'),
       Text('Cliente: ${saleResult['cliente_usado']}'),
       const SizedBox(height: 24),
       SizedBox(
        width: double.infinity,
        child: ElevatedButton(
         onPressed: () => Navigator.of(context).pop(),
         child: const Text('OK'),
        ),
       ),
      ],
     ),
    ),
   ),
  );
 }

 void _showErrorSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
   SnackBar(
    content: Text(message),
    backgroundColor: Colors.red,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
   ),
  );
 }

 @override
 Widget build(BuildContext context) {
  if (_isLoading) {
   return const Scaffold(
    backgroundColor: Color(0xFFF8FAFC),
    body: Center(
     child: CircularProgressIndicator(),
    ),
   );
  }

  return Scaffold(
   backgroundColor: const Color(0xFFF8FAFC),
   body: FadeTransition(
    opacity: _fadeAnimation,
    child: Column(
     children: [

      Container(
       height: 100,
       decoration: BoxDecoration(
        gradient: LinearGradient(
         begin: Alignment.topLeft,
         end: Alignment.bottomRight,
         colors: [
          const Color(0xFFE44D0F),
          const Color(0xFFFF5900),
         ],
        ),
        boxShadow: [
         BoxShadow(
          color: const Color(0xFF6366F1).withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
         ),
        ],
       ),
       child: SafeArea(
        child: Padding(
         padding: const EdgeInsets.symmetric(horizontal: 32),
         child: Row(
          children: [
           Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
             color: Colors.white.withOpacity(0.2),
             borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
             Icons.storefront,
             color: Colors.white,
             size: 28,
            ),
           ),
           const SizedBox(width: 16),
           Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
             const Text(
              'LOJA ANDRADE',
              style: TextStyle(
               color: Colors.white,
               fontSize: 28,
               fontWeight: FontWeight.bold,
               letterSpacing: -0.5,
              ),
             ),
             Text(
              'Usuário: ${widget.user.nome}',
              style: const TextStyle(
               color: Colors.white70,
               fontSize: 14,
               fontWeight: FontWeight.w500,
              ),
             ),
            ],
           ),
           const Spacer(),
           Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
             color: Colors.white.withOpacity(0.15),
             borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
             DateFormat('dd/MM/yyyy - HH:mm').format(DateTime.now()),
             style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
             ),
            ),
           ),
          ],
         ),
        ),
       ),
      ),

      Expanded(
       child: Row(
        children: [

         Expanded(
          flex: 2,
          child: Container(
           margin: const EdgeInsets.all(24),
           decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
             BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 8),
             ),
            ],
           ),
           child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
              Row(
               children: [
                Container(
                 width: 4,
                 height: 32,
                 decoration: BoxDecoration(
                  gradient: const LinearGradient(
                   begin: Alignment.topCenter,
                   end: Alignment.bottomCenter,
                   colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                 ),
                ),
                const SizedBox(width: 16),
                const Text(
                 'Catálogo de Produtos',
                 style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.5,
                 ),
                ),
               ],

              ),
              const SizedBox(height: 24),
              Container(
               decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
               ),
               child: TextField(
                controller: _searchController,
                onChanged: _filterProducts,
                decoration: const InputDecoration(
                 hintText: 'Buscar por nome ou código de barras...',
                 prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                 border: InputBorder.none,
                 contentPadding: EdgeInsets.all(20),
                 hintStyle: TextStyle(color: Color(0xFF64748B)),
                ),
               ),
              ),
              const SizedBox(height: 28),
              Expanded(
               child: _foundProducts.isNotEmpty
                   ? GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                 crossAxisCount: 4,
                 crossAxisSpacing: 16,
                 mainAxisSpacing: 16,
                 childAspectRatio: 1.3,
                ),
                itemCount: _foundProducts.length,
                itemBuilder: (context, index) {
                 final product = _foundProducts[index];
                 return Container(
                  decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(16),
                   border: Border.all(color: const Color(0xFFE2E8F0)),
                   boxShadow: [
                    BoxShadow(
                     color: Colors.black.withOpacity(0.02),
                     spreadRadius: 0,
                     blurRadius: 8,
                     offset: const Offset(0, 2),
                    ),
                   ],
                  ),
                  child: Material(
                   color: Colors.transparent,
                   child: InkWell(
                    onTap: () => _addToCart(product),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                     padding: const EdgeInsets.all(16),
                     child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                       Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                         gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                           const Color(0xFF6366F1).withOpacity(0.1),
                           const Color(0xFF8B5CF6).withOpacity(0.1),
                          ],
                         ),
                         borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                         Icons.shopping_bag_outlined,
                         color: Color(0xFFFF5900),
                         size: 24,
                        ),
                       ),
                       const SizedBox(height: 12),
                       Text(
                        product.descricao,
                        style: const TextStyle(
                         fontWeight: FontWeight.w600,
                         fontSize: 13,
                         color: Color(0xFF1F2937),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                       ),
                       const SizedBox(height: 4),
                       Text(
                        'Estoque: ${product.estoque}',
                        style: const TextStyle(
                         color: Color(0xFF64748B),
                         fontSize: 10,
                         fontWeight: FontWeight.w500,
                        ),
                       ),
                       const SizedBox(height: 8),
                       Text(
                        _currencyFormat.format(product.precoVenda),
                        style: const TextStyle(
                         color: Color(0xFF059669),
                         fontWeight: FontWeight.bold,
                         fontSize: 14,
                        ),
                       ),
                      ],
                     ),
                    ),
                   ),
                  ),
                 );
                },
               )
                   : Center(
                child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                  Container(
                   width: 80,
                   height: 80,
                   decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                   ),
                   child: const Icon(
                    Icons.search_off_rounded,
                    size: 40,
                    color: Color(0xFF64748B),
                   ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                   'Nenhum produto encontrado',
                   style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                   ),
                  ),
                 ],
                ),
               ),
              ),
             ],
            ),
           ),
          ),
         ),

         Expanded(
          flex: 1,
          child: Container(
           margin: const EdgeInsets.only(top: 24, right: 24, bottom: 24),
           decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
             BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 8),
             ),
            ],
           ),
           child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [

              Container(
               padding: const EdgeInsets.all(4),
               decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
               ),
               child: Row(
                children: [
                 Expanded(
                  child: GestureDetector(
                   onTap: () => setState(() {
                    _isCashSale = true;
                    _selectedCustomer = null;
                   }),
                   child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                     color: _isCashSale ? Colors.white : Colors.transparent,
                     borderRadius: BorderRadius.circular(8),
                     boxShadow: _isCashSale ? [
                      BoxShadow(
                       color: Colors.black.withOpacity(0.05),
                       blurRadius: 8,
                       offset: const Offset(0, 2),
                      ),
                     ] : null,
                    ),
                    child: Text(
                     'Avulso',
                     textAlign: TextAlign.center,
                     style: TextStyle(
                      color: _isCashSale ? const Color(0xFF1F2937) : const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                     ),
                    ),
                   ),
                  ),
                 ),
                 Expanded(
                  child: GestureDetector(
                   onTap: () => setState(() => _isCashSale = false),
                   child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                     color: !_isCashSale ? Colors.white : Colors.transparent,
                     borderRadius: BorderRadius.circular(8),
                     boxShadow: !_isCashSale ? [
                      BoxShadow(
                       color: Colors.black.withOpacity(0.05),
                       blurRadius: 8,
                       offset: const Offset(0, 2),
                      ),
                     ] : null,
                    ),
                    child: Text(
                     'Cliente',
                     textAlign: TextAlign.center,
                     style: TextStyle(
                      color: !_isCashSale ? const Color(0xFF1F2937) : const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                     ),
                    ),
                   ),
                  ),
                 ),
                ],
               ),
              ),

              if (!_isCashSale) ...[
               const SizedBox(height: 20),

               Container(
                decoration: BoxDecoration(
                 border: Border.all(color: const Color(0xFFE2E8F0)),
                 borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                 child: DropdownButton<ApiClient?>(
                  value: _selectedCustomer,
                  isExpanded: true,
                  hint: const Padding(
                   padding: EdgeInsets.all(16),
                   child: Text(
                    'Selecionar Cliente',
                    style: TextStyle(fontSize: 14),
                   ),
                  ),
                  onChanged: (ApiClient? customer) {
                   setState(() => _selectedCustomer = customer);
                  },
                  items: [
                   const DropdownMenuItem<ApiClient?>(
                    value: null,
                    child: Padding(
                     padding: EdgeInsets.all(16),
                     child: Text('Selecionar Cliente'),
                    ),
                   ),
                   ..._allClients.map((ApiClient customer) {
                    return DropdownMenuItem<ApiClient?>(
                     value: customer,
                     child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       mainAxisSize: MainAxisSize.min,
                       children: [
                        Text(
                         customer.nomeCliente,
                         style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                         ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                         children: [
                          Icon(
                           customer.isPessoaFisica ? Icons.person : Icons.business,
                           size: 12,
                           color: const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                           customer.documento,
                           style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                           ),
                          ),
                         ],
                        ),
                        if (customer.celular.isNotEmpty)
                         Row(
                          children: [
                           const Icon(
                            Icons.phone,
                            size: 12,
                            color: Color(0xFF64748B),
                           ),
                           const SizedBox(width: 4),
                           Text(
                            customer.celular,
                            style: const TextStyle(
                             fontSize: 12,
                             color: Color(0xFF64748B),
                            ),
                           ),
                          ],
                         ),
                       ],
                      ),
                     ),
                    );
                   }).toList(),
                  ],
                 ),
                ),
               ),
              ],
              Row(
               children: [
                Container(
                 width: 4,
                 height: 24,
                 decoration: BoxDecoration(
                  gradient: const LinearGradient(
                   begin: Alignment.topCenter,
                   end: Alignment.bottomCenter,
                   colors: [Color(0xFF059669), Color(0xFF10B981)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                 ),
                ),
                const SizedBox(width: 12),
                const Text(
                 'Carrinho',
                 style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                 ),
                ),
                const Spacer(),
                if (_cartItems.isNotEmpty)
                 IconButton(
                  onPressed: _clearCart,
                  icon: const Icon(Icons.clear_all_rounded),
                  tooltip: 'Limpar carrinho',
                  iconSize: 20,
                  color: const Color(0xFF64748B),
                 ),
               ],
              ),

              const SizedBox(height: 16),

              Expanded(
               child: _cartItems.isNotEmpty
                   ? ListView.builder(
                itemCount: _cartItems.length,
                itemBuilder: (context, index) {
                 final cartItem = _cartItems[index];
                 return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                   color: const Color(0xFFFAFBFC),
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                   padding: const EdgeInsets.all(16),
                   child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                     Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                       Expanded(
                        child: Text(
                         cartItem['name'],
                         style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF1F2937),
                         ),
                         maxLines: 2,
                         overflow: TextOverflow.ellipsis,
                        ),
                       ),
                       IconButton(
                        onPressed: () => _removeFromCart(index),
                        icon: const Icon(Icons.delete_outline_rounded),
                        iconSize: 18,
                        color: const Color(0xFFEF4444),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                       ),
                      ],
                     ),
                     const SizedBox(height: 8),
                     Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                       Text(
                        _currencyFormat.format(cartItem['price']),
                        style: const TextStyle(
                         color: Color(0xFF64748B),
                         fontSize: 12,
                         fontWeight: FontWeight.w500,
                        ),
                       ),
                       Container(
                        decoration: BoxDecoration(
                         color: Colors.white,
                         borderRadius: BorderRadius.circular(8),
                         border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                          GestureDetector(
                           onTap: () => _updateQuantity(
                            index,
                            cartItem['quantity'] - 1,
                           ),
                           child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                             borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(7),
                              bottomLeft: Radius.circular(7),
                             ),
                            ),
                            child: const Icon(
                             Icons.remove,
                             size: 16,
                             color: Color(0xFF6366F1),
                            ),
                           ),
                          ),
                          Container(
                           width: 40,
                           height: 32,
                           decoration: const BoxDecoration(
                            border: Border(
                             left: BorderSide(color: Color(0xFFE2E8F0)),
                             right: BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                           ),
                           child: Center(
                            child: Text(
                             '${cartItem['quantity']}',
                             style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                             ),
                            ),
                           ),
                          ),
                          GestureDetector(
                           onTap: () => _updateQuantity(
                            index,
                            cartItem['quantity'] + 1,
                           ),
                           child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                             borderRadius: BorderRadius.only(
                              topRight: Radius.circular(7),
                              bottomRight: Radius.circular(7),
                             ),
                            ),
                            child: const Icon(
                             Icons.add,
                             size: 16,
                             color: Color(0xFF6366F1),
                            ),
                           ),
                          ),
                         ],
                        ),
                       ),
                      ],
                     ),
                     const SizedBox(height: 8),
                     Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                       _currencyFormat.format(
                           cartItem['quantity'] * cartItem['price']
                       ),
                       style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                        fontSize: 15,
                       ),
                      ),
                     ),
                    ],
                   ),
                  ),
                 );
                },
               )
                   : Center(
                child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                  Container(
                   width: 80,
                   height: 80,
                   decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                   ),
                   child: const Icon(
                    Icons.shopping_cart_outlined,
                    size: 40,
                    color: Color(0xFF64748B),
                   ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                   'Carrinho vazio',
                   style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                   ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                   'Adicione produtos para continuar',
                   style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                   ),
                   textAlign: TextAlign.center,
                  ),
                 ],
                ),
               ),
              ),

              if (_cartItems.isNotEmpty) ...[
               const SizedBox(height: 20),

               Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                 color: const Color(0xFFF8FAFC),
                 borderRadius: BorderRadius.circular(16),
                 border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                  const Text(
                   'Descontos',
                   style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                   ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                   children: [
                    Expanded(
                     child: Container(
                      decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                       controller: _discountPercentController,
                       keyboardType: TextInputType.number,
                       inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                       ],
                       decoration: const InputDecoration(
                        labelText: 'Desconto %',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                        labelStyle: TextStyle(color: Color(0xFF64748B)),
                       ),
                       onChanged: _applyPercentageDiscount,
                      ),
                     ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                     child: Container(
                      decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                       controller: _discountValueController,
                       keyboardType: TextInputType.number,
                       inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                       ],
                       decoration: const InputDecoration(
                        labelText: 'Desconto R\$',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                        labelStyle: TextStyle(color: Color(0xFF64748B)),
                       ),
                       onChanged: _applyValueDiscount,
                      ),
                     ),
                    ),
                   ],
                  ),
                 ],
                ),
               ),

               const SizedBox(height: 24),

               Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                 gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                   const Color(0xFFE3E8EF),
                   const Color(0xFFDDDEDF),
                  ],
                 ),
                 borderRadius: BorderRadius.circular(20),
                 boxShadow: [
                  BoxShadow(
                   color: const Color(0xFF1E293B).withOpacity(0.3),
                   blurRadius: 20,
                   offset: const Offset(0, 8),
                  ),
                 ],
                ),
                child: Column(
                 children: [
                  Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                    const Text(
                     'Subtotal',
                     style: TextStyle(
                      color: Color(0xFF0C0C0C),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                     ),
                    ),
                    Text(
                     _currencyFormat.format(_subtotal),
                     style: const TextStyle(
                      color: Color(0xFF000000),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                     ),
                    ),
                   ],
                  ),
                  if (_totalDiscount > 0) ...[
                   const SizedBox(height: 12),
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                     const Text(
                      'Desconto',
                      style: TextStyle(
                       color: Color(0xFF000000),
                       fontSize: 14,
                       fontWeight: FontWeight.w500,
                      ),
                     ),
                     Text(
                      '- ${_currencyFormat.format(_totalDiscount)}',
                      style: const TextStyle(
                       color: Color(0xFFD30505),
                       fontSize: 14,
                       fontWeight: FontWeight.w600,
                      ),
                     ),
                    ],
                   ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                   height: 1,
                   width: double.infinity,
                   decoration: BoxDecoration(
                    gradient: LinearGradient(
                     begin: Alignment.centerLeft,
                     end: Alignment.centerRight,
                     colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.3),
                      Colors.transparent,
                     ],
                    ),
                   ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                    const Text(
                     'TOTAL',
                     style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000000),
                      letterSpacing: 1,
                     ),
                    ),
                    Text(
                     _currencyFormat.format(_finalTotal),
                     style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFA0303),
                      letterSpacing: -0.5,
                     ),
                    ),
                   ],
                  ),
                 ],
                ),
               ),

               const SizedBox(height: 28),

               Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                 gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                   Color(0xFF10B981),
                   Color(0xFF059669),
                  ],
                 ),
                 borderRadius: BorderRadius.circular(20),
                 boxShadow: [
                  BoxShadow(
                   color: const Color(0xFF10B981).withOpacity(0.4),
                   blurRadius: 20,
                   offset: const Offset(0, 8),
                  ),
                 ],
                ),
                child: ElevatedButton(
                 onPressed: _finalizeSale,
                 style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                   borderRadius: BorderRadius.circular(20),
                  ),
                 ),
                 child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                   Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 24,
                   ),
                   SizedBox(width: 12),
                   Text(
                    'Finalizar Venda',
                    style: TextStyle(
                     fontSize: 18,
                     fontWeight: FontWeight.bold,
                     color: Colors.white,
                     letterSpacing: 0.5,
                    ),
                   ),
                  ],
                 ),
                ),
               ),
              ],
             ],
            ),
           ),
          ),
         ),
        ],
       ),
      ),
     ],
    ),
   ),
  );
 }
}