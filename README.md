# pdv

Este é um novo projeto Flutter.

## ⚙️ Requisitos de Integração com o Backend (MapOS)

Para garantir que a funcionalidade de PDV funcione corretamente com o backend (MapOS), siga as instruções abaixo:

### 1. Criar a coluna `codigo_pdv` na tabela `usuarios`

No banco de dados do MapOS, adicione a seguinte coluna na tabela `usuarios`:

```sql
ALTER TABLE usuarios ADD COLUMN codigo_pdv VARCHAR(50);


Adicionar o Pdv.php na pasta controllers do MAP-OS



Adicionar CLIENTE_PADRAO_ID_VENDAS no .env do map-os
```




