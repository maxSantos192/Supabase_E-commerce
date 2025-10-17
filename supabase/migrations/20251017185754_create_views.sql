CREATE VIEW public.pedidos_detalhados AS
SELECT
  p.id AS pedido_id,
  p.status AS pedido_status,
  p.created_at AS data_pedido,
  c.id AS cliente_id,
  c.nome_completo AS cliente_nome,
  pr.id AS produto_id,
  pr.nome AS produto_nome,
  ip.quantidade,
  ip.preco_unitario,
  (ip.quantidade * ip.preco_unitario) AS subtotal
FROM
  public.pedidos p
JOIN
  public.clientes c ON p.cliente_id = c.id
JOIN
  public.itens_pedido ip ON p.id = ip.pedido_id
JOIN
  public.produtos pr ON ip.produto_id = pr.id;