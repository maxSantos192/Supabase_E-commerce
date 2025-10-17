ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.itens_pedido ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios podem ver e atualizar apenas seu proprio perfil"
ON public.clientes
FOR ALL
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

CREATE POLICY "Usuarios autenticados podem ver os produtos"
ON public.produtos
FOR SELECT
USING (auth.role() = 'authenticated');

CREATE POLICY "Usuarios podem criar pedidos para si mesmos"
ON public.pedidos
FOR INSERT
WITH CHECK (auth.uid() = cliente_id);

CREATE POLICY "Usuarios podem ver apenas seus proprios pedidos"
ON public.pedidos
FOR SELECT
USING (auth.uid() = cliente_id);

CREATE POLICY "Usuarios podem adicionar itens aos seus proprios pedidos"
ON public.itens_pedido
FOR INSERT
WITH CHECK (
  (SELECT cliente_id FROM public.pedidos WHERE id = pedido_id) = auth.uid()
);

CREATE POLICY "Usuarios podem ver itens de seus proprios pedidos"
ON public.itens_pedido
FOR SELECT
USING (
  (SELECT cliente_id FROM public.pedidos WHERE id = pedido_id) = auth.uid()
);