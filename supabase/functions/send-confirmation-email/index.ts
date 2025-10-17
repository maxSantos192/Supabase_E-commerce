import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { Resend } from 'npm:resend'

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')
const resend = new Resend(RESEND_API_KEY)

interface Pedido {
  id: number
  cliente_nome: string
  cliente_email: string
  total: number
}

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Método não permitido' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  try {
    const { record: pedido } = (await req.json()) as { record: Pedido }

    const { data, error } = await resend.emails.send({
      from: 'E-commerce <onboarding@resend.dev>', 
      to: [pedido.cliente_email],
      subject: `Confirmação do Pedido #${pedido.id}`,
      html: `
        <h1>Olá, ${pedido.cliente_nome}!</h1>
        <p>Seu pedido de número <strong>#${pedido.id}</strong> foi recebido com sucesso.</p>
        <p>Valor Total: R$ ${pedido.total.toFixed(2)}</p>
        <p>Obrigado por comprar conosco!</p>
      `,
    })

    if (error) {
      console.error({ error })
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    return new Response(JSON.stringify({ data }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (e) {
    console.error(e)
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})