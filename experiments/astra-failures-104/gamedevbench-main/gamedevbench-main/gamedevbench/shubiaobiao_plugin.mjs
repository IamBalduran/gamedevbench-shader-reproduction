// Adapt Shubiaobiao's non-streaming Responses JSON to OpenCode's event stream.
const itemIds = new Map()
const callIds = new Map()

function remember(item) {
  if (item?.type === 'reasoning' && typeof item.id === 'string' &&
      typeof item.encrypted_content === 'string')
    itemIds.set(item.encrypted_content, item.id)
  if (item?.type === 'function_call' && typeof item.id === 'string' &&
      typeof item.call_id === 'string')
    callIds.set(item.call_id, item.id)
}

export function responseToEventStream(result) {
  if (!Array.isArray(result.output) || !result.usage ||
      !['completed', 'incomplete'].includes(result.status))
    throw new Error('Unexpected non-streaming Responses payload')
  const events = []
  const emit = value => events.push(`data: ${JSON.stringify(value)}\n\n`)
  if (result.id && result.created_at && result.model)
    emit({ type: 'response.created', response: {
      id: result.id, created_at: result.created_at, model: result.model,
      service_tier: result.service_tier,
    } })
  result.output.forEach((item, output_index) => {
    if (!['reasoning', 'message', 'function_call'].includes(item.type))
      throw new Error(`Unsupported Responses output item: ${item.type}`)
    if (!item.id) throw new Error(`Missing Responses output item ID: ${item.type}`)
    remember(item)
    emit({ type: 'response.output_item.added', output_index, item })
    if (item.type === 'message') {
      for (const part of item.content ?? []) {
        if (part.type !== 'output_text')
          throw new Error(`Unsupported Responses message content: ${part.type}`)
        emit({ type: 'response.output_text.delta', item_id: item.id,
          delta: part.text ?? '' })
      }
    } else if (item.type === 'function_call') {
      emit({ type: 'response.function_call_arguments.delta', output_index,
        delta: item.arguments ?? '' })
    } else {
      for (const part of item.summary ?? []) {
        if (part.type !== 'summary_text') continue
        emit({ type: 'response.reasoning_summary_text.delta', item_id: item.id,
          summary_index: 0, delta: part.text ?? '' })
      }
    }
    emit({ type: 'response.output_item.done', output_index,
      item: item.type === 'function_call' ? { ...item, status: 'completed' } : item })
  })
  emit({ type: result.status === 'completed' ? 'response.completed' : 'response.incomplete',
    response: { usage: result.usage, incomplete_details: result.incomplete_details,
      service_tier: result.service_tier, reasoning: result.reasoning } })
  events.push('data: [DONE]\n\n')
  return events.join('')
}

export const ShubiaobiaoResponsesReplay = async () => ({
  config(config) {
    const provider = config.provider?.openai
    if (provider?.options?.baseURL !== 'https://api.shubiaobiao.cn/v1') return
    provider.options.fetch = async (input, init) => {
      const url = typeof input === 'string' ? input : input instanceof URL ? input.href : input.url
      if (!url.startsWith('https://api.shubiaobiao.cn/v1/responses')) return fetch(input, init)
      if (typeof init?.body !== 'string') throw new Error('Expected JSON Responses request')
      const body = JSON.parse(init.body)
      // This provider intermittently rejects replayed encrypted reasoning even
      // when the payload is unchanged. Tool calls and visible messages remain.
      if (Array.isArray(body.input))
        body.input = body.input.filter(item => item?.type !== 'reasoning')
      for (const item of body.input ?? []) {
        if (item?.id) continue
        const id = item?.type === 'reasoning' && item.encrypted_content
          ? itemIds.get(item.encrypted_content)
          : item?.type === 'function_call' && item.call_id
            ? callIds.get(item.call_id)
            : undefined
        if (id) item.id = id
      }
      const wasStreaming = body.stream === true
      if (wasStreaming) body.stream = false
      const response = await fetch(input, { ...init, body: JSON.stringify(body) })
      if (!response.ok || !wasStreaming) return response
      const result = await response.json()
      const events = responseToEventStream(result)
      const headers = new Headers(response.headers)
      headers.set('content-type', 'text/event-stream')
      headers.delete('content-length')
      headers.delete('content-encoding')
      return new Response(events, { status: response.status, headers })
    }
  },
})
