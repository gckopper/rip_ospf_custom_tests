# RIP vs OSPF — Testes de Convergência, Recuperação e Overhead

Este projeto compara os protocolos de roteamento dinâmico **RIP** e **OSPF** em um laboratório simples utilizando [FRRouting (FRR)](https://frrouting.org/) e [Containerlab](https://containerlab.dev/).

---

## Cenário de Execução
- **Sistema Operacional**: Linux (testado em Ubuntu dentro de VM VirtualBox).
- **Pré-requisitos**:
  - Docker
  - Containerlab
  - Curl (para instalar pacotes, se necessário)
- **Instalação Containerlab**:
  ```bash
  curl -sL https://get.containerlab.dev | sudo -E bash
  ```

---

## Estrutura do Projeto
- **Topologias**: `frr3_ospf.clab.yml` e `frr3_rip.clab.yml`
- **Configs FRR**: diretórios `cfg/ospf` e `cfg/rip`
- **Scripts**:
  - `run.sh`: executa um teste completo (auto-limpa, sobe a topologia, mede métricas, salva em `results/results.log`)
  - `clean.sh`: limpeza manual
- **Resultados**: `results/results.log`

---

## Como Executar
Exemplo OSPF:
```bash
./run.sh ospf
```

Exemplo RIP:
```bash
./run.sh rip
```

Os resultados são salvos em `results/results.log` com timestamp e métricas.

---

## Métricas Coletadas
1. **Tempo de convergência inicial**  
   Tempo até o primeiro ping de H1 para H3 funcionar após iniciar o lab.
2. **Tempo de recuperação de falha**  
   Tempo até ping voltar após desligar link R1–R2.
3. **Overhead de tráfego de controle**  
   Número de pacotes de controle (RIP → UDP/520, OSPF → IP proto 89) em 60s de rede estável.

---

## Observações
- Scripts já usam auto-sudo, mas se houver erro de permissão, rodar com:
  ```bash
  sudo -E ./run.sh ospf
  ```
- Os resultados são appendados em `results/results.log`.
