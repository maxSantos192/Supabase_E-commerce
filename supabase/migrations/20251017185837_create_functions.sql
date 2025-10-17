CREATE OR REPLACE FUNCTION public.calcular_total_pedido(p_pedido_id BIGINT)
RETURNS NUMERIC AS $$
DECLARE
  total_calculado NUMERIC;
BEGIN
  SELECT
    SUM(quantidade * preco_unitario) INTO total_calculado
  FROM
    public.itens_pedido
  WHERE
    pedido_id = p_pedido_id;

  RETURN COALESCE(total_calculado, 0);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.atualizar_total_pedido_trigger()
RETURNS TRIGGER AS $$
DECLARE
  v_pedido_id BIGINT;
BEGIN
  IF (TG_OP = 'DELETE') THEN
    v_pedido_id := OLD.pedido_id;
  ELSE
    v_pedido_id := NEW.pedido_id;
  END IF;

  UPDATE public.pedidos
  SET
    total = (
      SELECT
        calcular_total_pedido(v_pedido_id)
    )
  WHERE
    id = v_pedido_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_itens_pedido_change
AFTER INSERT
OR
UPDATE OR DELETE ON public.itens_pedido FOR EACH ROW
EXECUTE FUNCTION public.atualizar_total_pedido_trigger();