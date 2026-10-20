# ANS Beneficiários DW

Data warehouse em estrela com os beneficiários de planos de saúde da ANS,
em PostgreSQL no Docker, consumido pelo Power BI.

## Granularidade da fato

Cada linha de `fato_beneficiarios` representa as quantidades de beneficiários
(ativos, aderidos e cancelados) de **uma competência**, em **um plano de uma
operadora**, em **um município**, para **um perfil** (sexo, faixa etária,
faixa etária de reajuste e tipo de vínculo).

## Decisões de modelagem

- Códigos (operadora, plano, município) são texto, para preservar zeros e letras.
- Um plano é identificado por operadora + código + atributos, porque o mesmo
  código aparece em várias operadoras.
- Valores como "Não Identificado" e "Município ignorado" ficam como membros
  das dimensões, para que a fato continue ligada.