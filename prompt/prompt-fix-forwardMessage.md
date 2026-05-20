# Prompt: Corrigir endpoint forwardMessage para preservar link previews

## Contexto
Temos um endpoint customizado `POST /message/forwardMessage/{instance}` no nosso servidor Evolution API (baseado em Baileys/WhiskeySockets). O objetivo é encaminhar mensagens nativamente entre grupos WhatsApp, preservando 100% da fidelidade visual (thumbnails, link previews, formatação, metadados).

## Problema Atual
O forward funciona parcialmente:
- ✅ A label "Encaminhada" aparece corretamente no destino
- ✅ O texto da mensagem é preservado
- ❌ **Link previews com imagem (thumbnail/externalAdReply) NÃO são preservados**
- ❌ Mensagens com links chegam como texto puro, sem o card de preview

## Payload enviado pelo worker
```json
POST /message/forwardMessage/{monitorInstance}
{
  "number": "1234567890@g.us",
  "forwarding": {
    "key": {
      "remoteJid": "origGroupJid@g.us",
      "id": "MSG_ID_ORIGINAL",
      "fromMe": false
    }
  }
}
```

## Comportamento esperado
Quando a mensagem original contém um link com preview (ex: link do Shopee, YouTube, etc.), o forward deve preservar o `externalAdReply` completo, incluindo:
- `title`
- `body`
- `thumbnailUrl` ou `jpegThumbnail` (base64)
- `mediaUrl`
- `sourceUrl`

## Análise técnica do problema

### Hipótese principal
O `generateForwardMessageContent` do Baileys provavelmente está descartando o `contextInfo.externalAdReply` da mensagem original ao gerar o conteúdo de encaminhamento. Isso acontece porque:

1. O Baileys trata `externalAdReply` como parte do `contextInfo`, não do conteúdo da mensagem
2. Ao fazer forward, o `generateForwardMessageContent` cria um novo `contextInfo` com `isForwarded: true` e `forwardingScore`, mas **descarta o `externalAdReply` original**

### Solução sugerida
No handler do endpoint `forwardMessage`, após chamar `generateForwardMessageContent`, verificar se a mensagem original tinha `contextInfo.externalAdReply` e re-injetá-lo no conteúdo gerado.

Pseudocódigo:
```typescript
// 1. Buscar mensagem original do store
const msg = await instance.getMessage(key);

// 2. Gerar conteúdo de forward
const forwardContent = generateForwardMessageContent(msg.message, false);

// 3. Extrair externalAdReply da mensagem original (navegar wrappers)
const originalMessage = unwrapMessage(msg.message); // ephemeralMessage, viewOnceMessage, etc.
const originalContextInfo = getContextInfoFromMessage(originalMessage);
const externalAdReply = originalContextInfo?.externalAdReply;

// 4. Se existir, re-injetar no conteúdo gerado
if (externalAdReply) {
  const innerType = Object.keys(forwardContent)[0]; // ex: "extendedTextMessage"
  if (forwardContent[innerType]?.contextInfo) {
    forwardContent[innerType].contextInfo.externalAdReply = externalAdReply;
  }
}

// 5. Enviar via relayMessage
await instance.relayMessage(destJid, forwardContent, { messageId: generateMessageID() });
```

### Função auxiliar para extrair contextInfo
```typescript
function unwrapMessage(message: any): any {
  if (!message) return message;
  if (message.ephemeralMessage?.message) return unwrapMessage(message.ephemeralMessage.message);
  if (message.viewOnceMessage?.message) return unwrapMessage(message.viewOnceMessage.message);
  if (message.viewOnceMessageV2?.message) return unwrapMessage(message.viewOnceMessageV2.message);
  if (message.documentWithCaptionMessage?.message) return unwrapMessage(message.documentWithCaptionMessage.message);
  return message;
}

function getContextInfoFromMessage(message: any): any {
  if (!message) return null;
  const types = ['extendedTextMessage', 'imageMessage', 'videoMessage', 'documentMessage', 'audioMessage', 'stickerMessage', 'contactMessage', 'locationMessage'];
  for (const type of types) {
    if (message[type]?.contextInfo) return message[type].contextInfo;
  }
  return null;
}
```

## Validação
Após aplicar o fix, testar com:
1. Enviar link do Shopee/YouTube no grupo de origem
2. Verificar se no grupo destino aparece:
   - Label "Encaminhada" ✅
   - Card de preview com título + imagem ✅
   - Thumbnail clicável ✅

## Referências
- Baileys `generateForwardMessageContent`: https://github.com/WhiskeySockets/Baileys/blob/master/src/Utils/messages.ts
- O `externalAdReply` fica em `message.[type].contextInfo.externalAdReply`
- O `jpegThumbnail` pode estar como Buffer ou base64 string

## Observação
Se o `externalAdReply` não estiver presente na mensagem armazenada no store (alguns clientes não persistem), uma alternativa é copiar o `contextInfo` inteiro da mensagem original e fazer merge com o novo `contextInfo` de forward (preservando `isForwarded` e `forwardingScore`).
