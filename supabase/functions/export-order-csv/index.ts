import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface ItemPedido {
  produto_nome: string
  quantidade: number
  preco_unitario: number
  subtotal: number
}

serve(async (req) => {
  try {
    const { order_id } = await req.json()
    if (!order_id) {
      throw new Error('O ID do pedido (order_id) é obrigatório.')
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL'),
      Deno.env.get('SUPABASE_ANON_KEY'),
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    const { data, error } = await supabaseClient
      .from('pedidos_detalhados')
      .select('produto_nome, quantidade, preco_unitario, subtotal')
      .eq('pedido_id', order_id)

    if (error) {
      throw error
    }

    if (!data || data.length === 0) {
      return new Response(JSON.stringify({ error: 'Pedido não encontrado ou acesso negado.' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const items = data as ItemPedido[]
    const header = 'Produto,Quantidade,Preco Unitario,Subtotal\n'
    const rows = items
      .map(
        (item) =>
          `${item.produto_nome},${item.quantidade},${item.preco_unitario},${item.subtotal}`
      )
      .join('\n')

    const csvContent = header + rows

    return new Response(csvContent, {
      status: 200,
      headers: {
        'Content-Type': 'text/csv',
        'Content-Disposition': `attachment; filename="pedido_${order_id}.csv"`,
      },
    })
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})