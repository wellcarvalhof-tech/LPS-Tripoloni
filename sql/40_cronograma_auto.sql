-- 40 — O cronograma automático passa a ser gerado sob demanda
--
-- Por quê: até aqui o cronograma era recalculado a cada vez que a matriz desenhava. Mudar a
-- produtividade de um serviço, uma quantidade ou um feriado refazia o plano inteiro na hora,
-- sem ninguém mandar — e o cronograma que a obra tinha combinado mudava sozinho debaixo de
-- quem estava olhando.
--
-- Agora o cronograma é GERADO: o sistema guarda o cadastro do momento em que você mandou
-- gerar (serviços, saldos, calendário e o motor de cálculo), e a matriz passa a ser desenhada
-- a partir desse retrato. Mexer no cadastro depois não muda mais a matriz: aparece o aviso de
-- que o cronograma está desatualizado, e gerar de novo é uma decisão sua.
--
-- O que fica guardado aqui é o RETRATO DO CADASTRO, não os blocos desenhados. O desenho
-- continua sendo calculado — só que sempre a partir deste retrato, o que dá o mesmo resultado
-- toda vez. Os ajustes fixados na mão (ajustes_manuais) continuam valendo por cima e na hora,
-- porque ajustar a matriz é justamente o que se faz depois de gerar.
--
-- Rodar no SQL Editor do Supabase. Pode rodar mais de uma vez sem problema.

alter table public.obras add column if not exists cronograma_auto jsonb;

comment on column public.obras.cronograma_auto is
  'Retrato do cadastro usado para gerar o cronograma automático: {snap:{servicos,quantidades,feriados,motor}, em, por}. '
  'Quando {limpo:true}, a obra teve o cronograma apagado de propósito e a matriz fica vazia até alguém gerar de novo. '
  'Nulo quer dizer que a obra nunca gerou — nesse caso o sistema gera uma vez sozinho, para que obra antiga não abra vazia.';

-- Conferência depois de rodar:
--   select nome,
--          case
--            when cronograma_auto is null then 'nunca gerou'
--            when cronograma_auto->>'limpo' = 'true' then 'limpo de proposito'
--            else 'gerado em ' || (cronograma_auto->>'em')
--          end as cronograma
--     from public.obras order by nome;
