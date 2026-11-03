# Acesso remoto pelo Hamachi

O sistema local e o frontend React/Vite. Ele escuta em `0.0.0.0` na porta TCP `8080` e usa o Supabase hospedado como backend de dados e autenticacao. A porta e fixa: se estiver ocupada, o servidor mostra um erro, em vez de iniciar em outra porta.

## Instalar a inicializacao automatica

1. Clique com o botao direito em `instalar_inicializacao_automatica.bat`.
2. Selecione **Executar como administrador**.
3. O script cria ou atualiza a tarefa `Sistema Remoto Hamachi` e libera somente a porta TCP `8080` no Firewall do Windows.
4. O instalador tambem inicia a tarefa imediatamente se a porta `8080` estiver livre. Se ja houver um servidor na porta, ele preserva a instancia em execucao.
5. A tarefa inicia o sistema automaticamente no logon do usuario que executou o instalador. Executar o instalador novamente atualiza a mesma tarefa, sem duplicatas.

A tarefa executa em segundo plano, sem janela, e grava a saida em `.remote-access/server.log`. Ela nao tem limite de tres dias e tenta reiniciar apos falhas. O computador precisa permanecer ligado e sem suspender; a inicializacao automatica ocorre ao entrar no Windows, nao antes do logon.

Os arquivos `.bat` chamam os scripts PowerShell da mesma pasta por `-File`, para preservar corretamente caminhos com espacos e acentos. Mantenha os quatro arquivos de inicializacao e instalacao juntos na pasta do projeto.

O Windows precisa ter Node.js e npm instalados. As dependencias do projeto tambem precisam existir; se a pasta `node_modules` estiver ausente, execute `npm install` uma vez na pasta do projeto.

## Iniciar manualmente

Execute `iniciar_sistema.bat`. A janela deve permanecer aberta enquanto o sistema estiver em uso. Para encerrar, pressione `Ctrl+C`. Se a tarefa automatica ja estiver rodando, use o sistema diretamente; uma segunda inicializacao sera recusada para evitar conflito na porta `8080`.

## Descobrir o IPv4 do Hamachi

Abra o Hamachi e localize o endereco IPv4 exibido ao lado do botao de ligar, normalmente iniciado por `25.` ou `26.`. Outra opcao e executar `ipconfig` no Prompt de Comando e procurar o **Endereco IPv4** do adaptador Hamachi.

## Acessar de outro computador

Com os dois computadores conectados a mesma rede Hamachi, abra no navegador:

```text
http://IP_IPV4_DO_HAMACHI:8080
```

Exemplo: `http://25.9.190.20:8080`. Confira o endereco atual no servidor; ele pode mudar. Use `http://` e inclua `:8080`. `localhost` em outro computador aponta para esse outro computador.

## Testar o servidor

No computador servidor, abra `http://localhost:8080`. No outro computador, teste o endereco do Hamachi acima. Tambem e possivel executar no PowerShell do outro computador:

```powershell
Test-NetConnection IP_IPV4_DO_HAMACHI -Port 8080
```

O resultado esperado e `TcpTestSucceeded : True`.

## Se o acesso falhar

1. No servidor, teste `http://localhost:8080`. Se nao abrir, inicie o sistema ou consulte `.remote-access/server.log`.
2. Confira se o Hamachi esta ligado nos dois computadores e se ambos pertencem a mesma rede Hamachi. Use o IPv4 atual do servidor.
3. No computador remoto, execute `Test-NetConnection IP_IPV4_DO_HAMACHI -Port 8080`. Se o teste local funcionar e o remoto falhar, verifique a conexao Hamachi e a regra TCP `8080` do Firewall.
4. Se a pagina abrir mas o login falhar, a conexao ao frontend esta funcionando; anote a mensagem de login para diagnosticar a autenticacao separadamente.

Um teste pelo IPv4 Hamachi feito no proprio servidor confirma que o servidor responde nesse endereco, mas a conexao entre os dois computadores precisa ser testada no computador remoto.

## Remover a inicializacao automatica

Abra o **Agendador de Tarefas** como Administrador, localize `Sistema Remoto Hamachi` na Biblioteca do Agendador e escolha **Excluir**.

Opcionalmente, para remover tambem a liberacao do Firewall, abra um Prompt de Comando como Administrador e execute:

```bat
netsh advfirewall firewall delete rule name="Sistema Remoto - Porta 8080"
```
