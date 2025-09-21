# 🖥️ PDV Flutter (Windows / Web)

Este é um projeto de **PDV (Ponto de Venda)** desenvolvido em **Flutter**, compatível com **Windows** e **Web**.  
Ele se integra com o backend **MapOS**, permitindo gerenciar usuários, vendas e configurações diretamente do aplicativo.

---

## ⚙️ Requisitos de Integração com o Backend (MapOS)

Para garantir que a funcionalidade do PDV funcione corretamente com o MapOS, siga os passos abaixo:

### 1. Atualizar o banco de dados

No banco de dados do MapOS, adicione a coluna `codigo_pdv` na tabela `usuarios`:

```sql
ALTER TABLE usuarios ADD COLUMN codigo_pdv VARCHAR(50);
```

### 2. Adicionar o controlador PDV

Copie o arquivo `Pdv.php` para a pasta `controllers` do MapOS.

### 3. Configurar variável de ambiente

No arquivo `.env` do MapOS, adicione:

```
CLIENTE_PADRAO_ID_VENDAS=<ID_DO_CLIENTE_PADRAO>
```

---

## 🛠️ Pré-requisitos para desenvolvimento

Antes de rodar o projeto, instale os seguintes itens:

- **Flutter SDK**  
  [Instalação oficial do Flutter](https://flutter.dev/docs/get-started/install)

- **Dart SDK**  
  Normalmente já vem junto com o Flutter, mas você pode instalar separadamente:  
  [Instalação oficial do Dart](https://dart.dev/get-dart)

- **Android Studio** *(necessário apenas para builds Android)*  
  Instale o Android Studio e o Android SDK  
  Configure variáveis de ambiente `ANDROID_HOME` e `PATH`

- **.NET SDK** *(apenas se houver integração com serviços .NET)*  
  [Download do .NET](https://dotnet.microsoft.com/en-us/download)

- **Editor de código (opcional)**  
  VS Code ou IntelliJ/Android Studio

---

## 🚀 Configurando o projeto

### 1. Clonar o repositório

```bash
git clone <URL_DO_REPO>
cd <NOME_DO_REPO>
```

### 2. Instalar dependências

```bash
flutter pub get
```

### 3. Rodar no Windows

```bash
flutter run -d windows
```

### 4. Rodar na Web

```bash
flutter run -d chrome
```

### Build para produção

```bash
flutter build windows   # Windows
flutter build web       # Web
```

---

## 🔗 Integração com MapOS

- Certifique-se de que o backend esteja rodando e acessível.
- Configure a variável de ambiente `CLIENTE_PADRAO_ID_VENDAS` corretamente.
- O PDV lê a tabela `usuarios` para associar vendas ao `codigo_pdv` configurado.

---

## 📌 Observações

- Este projeto é voltado para uso interno e integração direta com MapOS.
- Certifique-se de ter permissões de acesso ao banco de dados.
- Funciona apenas com Windows e Web — builds mobile podem ser adicionados futuramente.
