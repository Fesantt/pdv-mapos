<?php

Class Pdv extends CI_Controller {
    function __construct() {
        parent::__construct();
    }

    public function index() 
    {
        $usuario = $this->auth();
        if( $usuario == false){
            $this->output->set_content_type('application/json');
            $this->output->set_output(json_encode([
                'success'=> false,
                'message'=> 'Acesso negado'
            ]));
            return;
        }

        $this->output->set_content_type('application/json');
        $produtos  = $this->db->get('produtos')->result();

        $this->output->set_output(json_encode([
            'success'=> true,
            'data'=> $produtos
        ]));
    }
    public function clientes() 
    {
        $usuario = $this->auth();
        if( $usuario == false){
            $this->output->set_content_type('application/json');
            $this->output->set_output(json_encode([
                'success'=> false,
                'message'=> 'Acesso negado'
            ]));
            return;
        }

        $this->output->set_content_type('application/json');
        $clientes  = $this->db->get('clientes')->result();

        $this->output->set_output(json_encode([
            'success'=> true,
            'data'=> $clientes
        ]));
    }

    public function login()
    {
        if( $this->input->method() != 'post'){
            $this->output->set_content_type('application/json');
            $this->output->set_output(json_encode([
                'success'=> false,
                'message'=> 'Método não permitido'
            ]));
            return;
        }

        $data = json_decode(file_get_contents('php://input'), true);
        if( isset($data['codigo_pdv'])){
            $this->output->set_content_type('application/json');
            $this->output->set_output(json_encode([
                'success'=> false,
                'message'=> 'Código PDV é obrigatório'
            ]));
        }
        $usuario = $this->db->get_where('usuarios', ['codigo_pdv'=> $data['codigo_pdv']])->row();
        if($usuario) {
            $this->output->set_content_type('application/json');
            $this->output->set_output(json_encode([
                'success'=> true,
                'data'=> $usuario
            ]));
        } else {
            $this->output->set_content_type('application/json');
            $this->output->set_output(json_encode([
                'success'=> false,
                'message'=> 'Usuário não encontrado'
            ]));
        }
    }

    private function auth()
    {
        $headers = $this->input->request_headers();

        if(!isset($headers['Authorization'])){
            return false;
        }

        $usuario = $this->db->get_where('usuarios', ['codigo_pdv'=> $headers['Authorization']])->row();

        if($usuario){
            return $usuario;
        }else{
            return false;
        }
    }

    public function criarVenda()
    {
         $usuario = $this->auth();
        if( $usuario == false){
            $this->output->set_content_type('application/json');
            $this->output->set_output(json_encode([
                'success'=> false,
                'message'=> 'Acesso negado'
            ]));
            return;
        }

        $this->load->database();

        $data = json_decode(file_get_contents('php://input'), true);
        if (!$data) {
            return $this->output
                        ->set_status_header(400)
                        ->set_content_type('application/json')
                        ->set_output(json_encode(['error' => 'Dados inválidos']));
        }

        $clienteId = isset($data['clientes_id']) && !empty($data['clientes_id']) 
            ? $data['clientes_id'] 
            : $_ENV['CLIENTE_PADRAO_ID_VENDAS'];

        $produtos  = $data['produtos'];

        $this->db->trans_begin();

        try {

            $vendaData = [
                'dataVenda'   => date('Y-m-d H:i:s'),
                'valorTotal'  => 0,
                'desconto'    => 0,
                'valor_desconto' => 0,
                'tipo_desconto'  => null,
                'faturado'    => 0,
                'observacoes' => null,
                'observacoes_cliente' => null,
                'clientes_id' => $clienteId,
                'usuarios_id' => 1, 
                'lancamentos_id' => null,
                'status'      => 'aberta',
                'garantia'    => null,
            ];
            $this->db->insert('vendas', $vendaData);
            $vendaId = $this->db->insert_id();

            $valorTotal = 0;

            foreach ($produtos as $p) {
                $produto = $this->db->get_where('produtos', ['idProdutos' => $p['idProdutos']])->row();

                if (!$produto) {
                    throw new Exception("Produto {$p['idProdutos']} não encontrado");
                }

                if ($produto->estoque < $p['quantidade']) {
                    throw new Exception("Estoque insuficiente para {$produto->descricao}");
                }

                $subTotal = $produto->precoVenda * $p['quantidade'];
                $valorTotal += $subTotal;

                $itemData = [
                    'subTotal'   => $subTotal,
                    'quantidade' => $p['quantidade'],
                    'preco'      => $produto->precoVenda,
                    'vendas_id'  => $vendaId,
                    'produtos_id'=> $produto->idProdutos
                ];
                $this->db->insert('itens_de_vendas', $itemData);

                $this->db->where('idProdutos', $produto->idProdutos)
                         ->update('produtos', ['estoque' => $produto->estoque - $p['quantidade']]);
            }

            $this->db->where('idVendas', $vendaId)
                     ->update('vendas', ['valorTotal' => $valorTotal]);

            if ($this->db->trans_status() === FALSE) {
                throw new Exception("Erro ao salvar venda");
            }

            $this->db->trans_commit();
            $this->log("Venda {$vendaId} criada pelo usuário {$usuario->nome}");
            return $this->output
                        ->set_content_type('application/json')
                        ->set_output(json_encode([
                            'success' => true,
                            'idVendas' => $vendaId,
                            'valorTotal' => $valorTotal,
                            'cliente_usado' => $clienteId
                        ]));

        } catch (Exception $e) {
            $this->db->trans_rollback();

            return $this->output
                        ->set_status_header(400)
                        ->set_content_type('application/json')
                        ->set_output(json_encode(['error' => $e->getMessage()]));
        }
    }

    private function log($message)
    {
        $usuario = $this->auth();

        if( $usuario == false){
            $this->output->set_content_type('application/json');
            $this->output->set_output(json_encode([
                'success'=> false,
                'message'=> 'Acesso negado'
            ]));
            return;
        }

        $this->db->insert('logs', [
            'tarefa' => $message,
            'data' => date('Y-m-d'),
            'hora' => date('H:i:s'),
            'usuario' => $usuario->nome
        ]);
    }

}