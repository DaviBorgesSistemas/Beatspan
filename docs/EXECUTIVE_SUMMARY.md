# Beatspan — Resumo Executivo
**Projeto:** Beatspan
**Data da análise:** 2026-09-12
**Versão do documento:** 3.0
**Público-alvo:** Produto, Negócio, Liderança

---

## Avaliação Geral: 6 de 10

O Beatspan é um aplicativo móvel tecnicamente bem construído para o estágio atual de desenvolvimento. A base de código é organizada, o sistema de integração com Spotify funciona corretamente e a equipe demonstra boas práticas de engenharia. O principal bloqueador para o lançamento público é um problema de segurança que pode ser corrigido rapidamente. O app ainda não tem a lógica de jogo completa, o que é esperado para um MVP de validação técnica.

---

## Riscos Mais Relevantes

### 1. Credenciais do Spotify disponíveis para qualquer pessoa com o APK
**Impacto:** Qualquer pessoa que baixar o arquivo de instalação do app pode extrair as chaves de acesso ao Spotify com ferramentas públicas disponíveis na internet. Isso permite que terceiros usem a conta do app no Spotify para fins não autorizados, podendo levar ao bloqueio do app pela Spotify. **Este risco precisa ser eliminado antes de qualquer distribuição pública**, mesmo para beta fechado.

### 2. Componente de software com versão problemática em uso
**Impacto:** Um componente de terceiros (biblioteca de sistema) está sendo usado em uma versão que foi retirada pelo próprio fabricante — o equivalente a usar um produto com recall voluntário. O risco varia de instabilidade a falhas silenciosas, particularmente em dispositivos iOS.

### 3. Jogo sem mecânicas de jogo
**Impacto:** O app lê QR codes e reproduz músicas corretamente, mas não implementa pontuação, rodadas, linha do tempo ou qualquer outra mecânica de jogo. Sem isso, o produto não pode ser lançado ao público como um jogo. Trata-se de uma limitação conhecida e esperada nesta fase, mas precisa ter data de entrega definida.

### 4. Dependências de software desatualizadas
**Impacto:** Sete bibliotecas principais usadas pelo app têm versões mais novas com melhorias e correções de segurança que não podem ser atualizadas diretamente agora por incompatibilidades entre si. Quanto mais tempo passa sem atualizar, mais difícil e arriscado fica o processo de manutenção.

### 5. Ausência de política de privacidade no app
**Impacto:** Antes de qualquer lançamento público, a lei brasileira (LGPD) exige que usuários saibam quais dados são coletados e possam consentir. O app coleta dados de uso via Firebase Analytics, mas não apresenta nenhuma tela de consentimento ou link para política de privacidade.

---

## Pontos Fortes

### 1. Base técnica sólida
A arquitetura do app está bem organizada e segue padrões profissionais. O código é claro, as responsabilidades são bem separadas e o tratamento de erros é robusto.

### 2. Processo de desenvolvimento maduro para o porte
O app tem uma esteira de verificação automática que detecta segredos vazados, verifica a qualidade do código e roda testes a cada mudança. Isso reduz o risco de problemas chegarem à produção.

### 3. Monitoramento de falhas em produção
O app já está configurado para enviar relatórios de erro automaticamente quando algo dá errado no celular do usuário, sem necessidade de o usuário reportar manualmente.

### 4. Integração Spotify robusta
O fluxo de leitura de QR code → busca da música → reprodução via Spotify funciona corretamente, com tratamento de falhas de rede, retry automático e fallback para prévia de 30 segundos quando o Spotify Premium não está disponível.

### 5. Experiência visual consistente
O app tem um sistema de cores, tipografia e componentes visuais coerentes, o que facilita a manutenção da identidade visual à medida que novas telas são adicionadas.

---

## Recomendação Objetiva

**Ação imediata (antes de qualquer distribuição):** Corrigir o problema das credenciais do Spotify no arquivo de instalação. Esta correção é simples (estimada em menos de meio dia de trabalho) e é pré-requisito inegociável para qualquer entrega ao público.

**Próximas 4 semanas:** Resolver o componente com versão problemática, corrigir 3-4 questões técnicas menores identificadas e elevar a cobertura de testes automáticos.

**Próximos 3 meses:** Implementar as mecânicas de jogo (rodadas, pontuação, linha do tempo), configurar o build para iOS e automatizar o processo de lançamento de novas versões.

**Próximos 12 meses:** Internacionalização para inglês, maturação da observabilidade e manutenção contínua das dependências de software.
