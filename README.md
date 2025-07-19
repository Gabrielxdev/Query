# 📊 SQL Analytics — Customer & Product Reporting

Este repositório contém consultas SQL para análises avançadas sobre vendas, clientes e produtos, usando a camada `gold` do Data Warehouse. As queries aqui desenvolvidas têm como objetivo fornecer insights estratégicos para tomada de decisão.

## 📈 Funcionalidades por Query

### 1️⃣ **Change Over Time - Trends**
Analisa como métricas evoluem ao longo do tempo para identificar tendências e sazonalidade.
- **Propósito:**
  - Rastrear tendências ao longo do tempo (ano e mês).
  - Descobrir padrões sazonais.
  - Métricas agregadas: vendas totais, número de clientes distintos, quantidade total.

### 2️⃣ **Cumulative Analysis**
Análise acumulada e média móvel ao longo do tempo.
- **Propósito:**
  - Entender o crescimento progressivo do negócio.
  - Calcular vendas acumuladas.
  - Calcular a média móvel do preço médio de vendas.

### 3️⃣ **Performance Analysis**
Comparar desempenho atual com histórico e metas.
- **Propósito:**
  - Comparar vendas anuais de produtos com sua média histórica.
  - Realizar análise YoY (Year-over-Year) para identificar aumento ou queda.
  - Classificar produtos como acima, abaixo ou igual à média.

### 4️⃣ **Category Contribution**
Determinar a contribuição de cada categoria para as vendas totais.
- **Propósito:**
  - Identificar categorias com maior participação no faturamento.
  - Calcular percentual de contribuição por categoria.

### 5️⃣ **Product Segmentation**
Segmentar produtos em faixas de custo.
- **Propósito:**
  - Distribuir produtos em intervalos de preços.
  - Quantificar produtos em cada faixa.

### 6️⃣ **Customer Segmentation**
Segmentar clientes com base em seu histórico e gasto.
- **Propósito:**
  - Classificar clientes como **VIP**, **Regular** ou **New**.
  - Considerar tempo de relacionamento (lifespan) e gasto total.

---

## 📋 Relatórios

### 🧑‍💼 **Customer Report**
Criação da view `gold.report_customer`.

- **Propósito:**
  - Resumir comportamento e métricas dos clientes.
  - Segmentar por faixa etária: Under 20, 20–29, 30–39, 40–49, 50+.
  - Segmentar por comportamento de compra: VIP, Regular, New.
  - Métricas:
    - Pedidos totais, vendas totais, quantidade comprada.
    - Número de produtos distintos adquiridos.
    - Lifespan (meses de relacionamento), recency (última compra).
    - KPIs: Average Order Value (AOV), Average Monthly Spend.

### 📦 **Product Report**
Criação da view `gold.report_products`.

- **Propósito:**
  - Consolidar métricas e comportamento dos produtos.
  - Classificar produtos por desempenho: High-Performer, Mid-Range, Low-Performer.
  - Métricas:
    - Pedidos totais, vendas totais, quantidade vendida.
    - Número de clientes únicos.
    - Lifespan, recency (última venda).
    - KPIs: Average Order Revenue (AOR), Average Monthly Revenue, preço médio de venda.

---

## 📂 Consultas Finais

As views criadas podem ser consultadas diretamente:
```sql
SELECT * FROM gold.report_customer;

SELECT * FROM gold.report_products;
