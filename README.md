# RIP vs OSPF — Testes de Convergência, Recuperação e Overhead

Este projeto compara os protocolos de roteamento dinâmico **RIP** e **OSPF** em um laboratório simples utilizando [FRRouting (FRR)](https://frrouting.org/) e [Containerlab](https://containerlab.dev/).

---

## Cenário de Execução

- **Sistema Operacional**: Linux (testado em Ubuntu dentro de VM VirtualBox).
- **Pré-requisitos**:
  - Docker
  - Containerlab
  - Curl (para instalação de pacotes se necessário)

Instalação Containerlab:
```bash
curl -sL https://get.containerlab.dev | sudo -E bash
```

---

## Topologia

- **Roteadores**: `ra`, `rb`, `rc`
- **Hosts**:
  - `h1` conectado ao `ra`
  - `h2` conectado ao `ra`
  - `h3` conectado ao `rb`
  - `h4` conectado ao `rc`
- **Links**:
  - `ra ↔ rb`
  - `ra ↔ rc`
  - `rb ↔ rc`
  - `h1 ↔ ra`
  - `h2 ↔ ra`
  - `h3 ↔ rb`
  - `h4 ↔ rc`

### Diagrama da Topologia

- **ra, rb, rc** formam uma malha completa (triângulo).
- h1 e h2 estão no router A (ra), cada um em uma LAN distinta.
- h3 está no router B (rb).
- h4 está no router C (rc).

---

## Estrutura do Projeto

- **Topologias**: `frr3_ospf.clab.yml` e `frr3_rip.clab.yml`
- **Configurações FRR**: diretórios `cfg/ospf` e `cfg/rip`
- **Scripts**:
  - `run2.sh <ospf|rip>` → auto-limpa, sobe a topologia, configura hosts, mede métricas e salva em `results/results.log`
  - `clean.sh` → limpeza manual completa
- **Resultados**: `results/results.log`

---

## Como Executar

Exemplo OSPF:
```bash
./run2.sh ospf
```

Exemplo RIP:
```bash
./run2.sh rip
```

Se ocorrer erro de permissão, utilize:
```bash
sudo -E ./run2.sh ospf
```

---

## Métricas Coletadas

1. **Tempo de convergência inicial**  
   Tempo até o **primeiro ping de h1 → h4** funcionar após iniciar o lab.

2. **Tempo de recuperação de falha**  
   Tempo até ping voltar após **derrubar o link ra–rb** (`ra:eth1`).

3. **Overhead de tráfego de controle**  
   Número de pacotes de controle em 60s:
   - RIP → `udp port 520`
   - OSPF → `ip proto 89`

---

## Observações

- Scripts já usam auto-sudo para `docker` e `containerlab`.  
- Todos os resultados são **appendados** em `results/results.log` com timestamp.  
- O experimento foi projetado para ser simples, focando em **comparar claramente o comportamento do RIP e do OSPF**.

---
