# Backend de E-commerce com Supabase

Este repositório contém a implementação de um backend para um sistema de e-commerce. O projeto foi construído inteiramente sobre a plataforma Supabase, utilizando seus principais recursos para criar uma solução robusta, segura e escalável.

## Funcionalidades Implementadas

- **Estrutura de Banco de Dados:** Modelagem e criação de tabelas para gerenciar clientes, produtos, pedidos e itens_pedido.
- **Segurança com Row-Level Security (RLS):** Implementação de políticas de segurança para garantir que os usuários só possam acessar e manipular seus próprios dados.
- **Automação com Funções e Triggers:** Criação de funções em PL/pgSQL para automatizar o cálculo do valor total dos pedidos, garantindo consistência dos dados.
- **Consultas Eficientes com Views:** Desenvolvimento de uma view para simplificar a consulta de dados detalhados de pedidos.
- **Serverless com Edge Functions:**
  - Uma função para o envio de e-mails de confirmação de novos pedidos.
  - Uma função para exportar os dados de um pedido em formato .csv.

## Estrutura

O código está organizado para seguir as melhores práticas e convenções da Supabase CLI:

- `/supabase/migrations`: Contém os arquivos SQL que definem a estrutura do banco de dados (tabelas, views, funções e políticas de RLS).
- `/supabase/functions`: Contém o código-fonte (TypeScript/Deno) para as Edge Functions serverless.
- `/supabase/.env.example`: Contém exemplos das variáveis de ambiente para rodar o projeto local.

## Como Executar o Projeto

Para configurar e testar este projeto em seu próprio ambiente Supabase, siga os passos abaixo.

### Pré-requisitos:

- [Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started) instalada.
- Conta no Supabase e um novo projeto criado.
- Conta no [Resend](https://resend.com/) para o envio de e-mails e uma chave de API.

### Passos

- **1. Clone o repositório**

```bash
  git clone https://github.com/maxSantos192/Supabase_E-commerce
```

- **2. Vincule ao seu projeto Supabase:**

```bash
  supabase login
  supabase link --project-ref <seu-project-ref>
```

- **3. Configure as variáveis de ambiente:**
  - Crie um arquivo `.env.local` na pasta `supabase/`.
  - Adicione sua chave de API do Resend:

```bash
  RESEND_API_KEY=suaChaveSecretaAqui
```

- Envie o segredo para o projeto Supabase remoto:

```bash
  supabase secrets set --env-file ./supabase/.env.local
```

- **4. Aplique as migrações do banco de dados:**

```bash
  supabase db push
```

- **5. Faça o deploy das Edge Functions:**

```bash
  supabase functions deploy --project-ref <seu-project-ref>
```

- **6. Configure o Database Webhook:**
  - No painel do seu projeto Supabase, vá em `Database > Webhooks`.
  - Crie um novo webhook na tabela pedidos para o evento `INSERT`.
  - Configure-o para chamar a Edge Function `send-confirmation-email` via `POST`.

## Decisões de Implementação e Lógica

**1. Estrutura do Banco de Dados**

- **Tabela clientes:** Em vez de recriar um sistema de autenticação, a tabela clientes funciona como um "perfil" que estende a tabela auth.users nativa do Supabase. A chave primária id é uma chave estrangeira para auth.users(id), garantindo a integração perfeita com o sistema de autenticação do Supabase.

- **Tipo ENUM para Status:** O status do pedido (pedidos.status) utiliza um tipo ENUM do PostgreSQL. Isso garante a integridade dos dados, restringindo os valores a um conjunto pré-definido (pendente, pago, etc.) e evitando inconsistências.

- **Tabela de Junção itens_pedido:** Para modelar a relação N-para-N entre pedidos e produtos, foi criada a tabela itens_pedido. Nela, o campo preco_unitario armazena o preço do produto no momento da compra, garantindo um registro histórico preciso mesmo que o preço do produto mude no futuro.

**2. Segurança (RLS)**

- Todas as tabelas sensíveis têm o RLS ativado.
- **Política de Clientes:** Um usuário só pode ver e editar seu próprio perfil na tabela `clientes`.
- **Política de Pedidos:** Um usuário pode criar pedidos para si mesmo e visualizar apenas os pedidos que lhe pertencem. A consulta na `view` `pedidos_detalhados` herda automaticamente essas permissões.
- **Acesso Público a Produtos:** A tabela `produtos` permite a leitura por qualquer usuário autenticado, pois são informações públicas dentro do e-commerce.

**3. Automações com Funções e Triggers**

- Uma função calcular_total_pedido foi criada para somar os subtotais de todos os itens de um pedido.
- Um trigger é acionado sempre que há uma alteração (INSERT, UPDATE, DELETE) na tabela `itens_pedido`.
- Este trigger executa a função, que recalcula o valor total e o atualiza na tabela `pedidos`, garantindo que o total esteja sempre correto sem a necessidade de intervenção da aplicação cliente.

**4. Edge Functions**

- **send-confirmation-email:** Utiliza o serviço Resend para o envio de e-mails transacionais. A função é acionada por um Database Webhook, desacoplando a lógica de envio de e-mail da inserção no banco e tornando o sistema mais resiliente.
- **export-order-csv:** Esta função recebe um `order_id` e cria um cliente Supabase utilizando o token de autorização do usuário que fez a requisição. Isso garante que as políticas de RLS sejam aplicadas, impedindo que um usuário exporte dados de um pedido que não lhe pertence. O resultado é um arquivo `.csv` pronto para download.
