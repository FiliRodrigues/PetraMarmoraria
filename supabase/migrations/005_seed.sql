-- 005_seed.sql
-- Seed data for testing and demo purposes in Petra ERP Marmoraria

-- 1. Seed Auth Users into auth.users schema
-- Note: Encrypted passwords are set to "password123" using standard bcrypt
INSERT INTO auth.users (
  id,
  instance_id,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_super_admin,
  created_at,
  updated_at,
  aud,
  role
) VALUES
-- Admin
('a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', '00000000-0000-0000-0000-000000000000', 'admin@petra.com', '$2a$10$vI8PjS5D3oQp2b8hYpC3veOqDq6bC95uYm4yA7/Kz5zHh98v1a0Y2', now(), '{"provider":"email","providers":["email"]}', '{"name":"Administrador Petra"}', false, now(), now(), 'authenticated', 'authenticated'),
-- Vendedor
('b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', '00000000-0000-0000-0000-000000000000', 'vendedor@petra.com', '$2a$10$vI8PjS5D3oQp2b8hYpC3veOqDq6bC95uYm4yA7/Kz5zHh98v1a0Y2', now(), '{"provider":"email","providers":["email"]}', '{"name":"Vendedor Petra"}', false, now(), now(), 'authenticated', 'authenticated'),
-- Cortador
('c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f', '00000000-0000-0000-0000-000000000000', 'cortador@petra.com', '$2a$10$vI8PjS5D3oQp2b8hYpC3veOqDq6bC95uYm4yA7/Kz5zHh98v1a0Y2', now(), '{"provider":"email","providers":["email"]}', '{"name":"Cortador Petra"}', false, now(), now(), 'authenticated', 'authenticated'),
-- Montador
('d4e5f6a7-b8c9-0d1e-2f3a-4b5c6d7e8f9a', '00000000-0000-0000-0000-000000000000', 'montador@petra.com', '$2a$10$vI8PjS5D3oQp2b8hYpC3veOqDq6bC95uYm4yA7/Kz5zHh98v1a0Y2', now(), '{"provider":"email","providers":["email"]}', '{"name":"Montador Petra"}', false, now(), now(), 'authenticated', 'authenticated'),
-- Entregador
('e5f6a7b8-c9d0-1e2f-3a4b-5c6d7e8f9a0b', '00000000-0000-0000-0000-000000000000', 'entregador@petra.com', '$2a$10$vI8PjS5D3oQp2b8hYpC3veOqDq6bC95uYm4yA7/Kz5zHh98v1a0Y2', now(), '{"provider":"email","providers":["email"]}', '{"name":"Entregador Petra"}', false, now(), now(), 'authenticated', 'authenticated')
ON CONFLICT (id) DO NOTHING;

-- 2. Update generated profiles to set custom roles, names, phone numbers, and ensure status is active
-- (The trigger "on_auth_user_created" auto-created these, we configure them to test RLS and roles)
UPDATE public.profiles SET role = 'admin', name = 'Administrador Petra', phone = '(11) 99999-1111' WHERE id = 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d';
UPDATE public.profiles SET role = 'vendedor', name = 'Vendedor Petra', phone = '(11) 99999-2222' WHERE id = 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e';
UPDATE public.profiles SET role = 'cortador', name = 'Cortador Petra', phone = '(11) 99999-3333' WHERE id = 'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f';
UPDATE public.profiles SET role = 'montador', name = 'Montador Petra', phone = '(11) 99999-4444' WHERE id = 'd4e5f6a7-b8c9-0d1e-2f3a-4b5c6d7e8f9a';
UPDATE public.profiles SET role = 'entregador', name = 'Entregador Petra', phone = '(11) 99999-5555' WHERE id = 'e5f6a7b8-c9d0-1e2f-3a4b-5c6d7e8f9a0b';

-- 3. Seed Customers
INSERT INTO public.customers (id, name, cpf_cnpj, phone, phone2, email, address, city, state, notes) VALUES
('f1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'Roberto Silva', '123.456.789-00', '(11) 98888-1111', '(11) 97777-1111', 'roberto.silva@email.com', 'Av. Paulista, 1000, Ap 51', 'São Paulo', 'SP', 'Cliente residencial exigente, prefere contato por WhatsApp.'),
('a2b3c4d5-e6f7-8a9b-0c1d-2e3f4a5b6c7d', 'Construtora Alvorada Ltda', '12.345.678/0001-99', '(11) 3333-2222', NULL, 'compras@alvorada.com.br', 'Rua dos Pinheiros, 450', 'São Paulo', 'SP', 'Parceiro corporativo. Faturamento em 30 dias.'),
('b3c4d5e6-f7a8-9b0c-1d2e-3f4a5b6c7d8e', 'Maria Oliveira', '987.654.321-99', '(11) 98888-3333', NULL, 'maria.oliveira@email.com', 'Rua Augusta, 1200', 'São Paulo', 'SP', 'Indicada pelo arquiteto Marcos Pontes.'),
('c4d5e6f7-a8b9-0c1d-2e3f-4a5b6c7d8e9f', 'Ana Souza', '456.789.123-11', '(19) 98888-4444', '(19) 3232-4444', 'ana.souza@email.com', 'Av. José de Souza Campos, 800', 'Campinas', 'SP', NULL),
('d5e6f7a8-b9c0-1d2e-3f4a-5b6c7d8e9f0a', 'Carlos Santos', '789.123.456-22', '(11) 98888-5555', NULL, 'carlos.santos@email.com', 'Rua Pamplona, 300', 'São Paulo', 'SP', 'Entregar somente após as 14h.')
ON CONFLICT (id) DO NOTHING;

-- 4. Seed Products
INSERT INTO public.products (id, name, type, unit_price, unit, active) VALUES
('e1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'Mármore Carrara', 'marmore', 1200.00, 'm2', true),
('e2b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'Granito Preto São Gabriel', 'granito', 450.00, 'm2', true),
('e3b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'Quartzo Branco Estelar', 'quartzo', 950.00, 'm2', true),
('e4b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'Ardósia Cinza', 'ardosia', 180.00, 'm2', true),
('e5b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'Cuba de Embutir Tramontina', 'outro', 350.00, 'unidade', true),
('e6b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'Rodapé Mármore Travertino', 'marmore', 120.00, 'ml', true)
ON CONFLICT (id) DO NOTHING;

-- 5. Seed Service Orders
INSERT INTO public.service_orders (id, display_number, customer_id, description, status, queue_position, material, edge_type, measurements, total_value, status_changed_at, scheduled_date) VALUES
-- OS #1: Corte (Normal status)
('d1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 1, 'f1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'Bancada Cozinha Americana', 'corte', 1, 'Mármore Carrara', 'Bisotado', '{"largura": 2.40, "altura": 0.60, "espessura": 0.02, "formato": "L"}', 3200.00, now() - interval '1 day', current_date + 10),

-- OS #2: Esperando Material (Inactive 4 days -> Warning state. Queue position 2. Overtaken by OS #3, creating a queue violation)
('d2b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 2, 'a2b3c4d5-e6f7-8a9b-0c1d-2e3f4a5b6c7d', 'Soleiras Bloco A', 'esperando_material', 2, 'Granito Preto São Gabriel', 'Reto', '{"largura": 1.20, "altura": 0.15, "espessura": 0.02, "formato": "Reto"}', 8500.00, now() - interval '4 days', current_date + 15),

-- OS #3: Corte (Queue position 3, status advanced. Overtook OS #2 -> Violator order)
('d3b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 3, 'b3c4d5e6-f7a8-9b0c-1d2e-3f4a5b6c7d8e', 'Lavatório Suíte Master', 'corte', 3, 'Quartzo Branco Estelar', '45 Graus', '{"largura": 1.50, "altura": 0.55, "espessura": 0.02, "formato": "Reto"}', 1800.00, now() - interval '2 hours', current_date + 7),

-- OS #4: Orçamento (Normal, new budget)
('d4b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 4, 'c4d5e6f7-a8b9-0c1d-2e3f-4a5b6c7d8e9f', 'Área Gourmet Completa', 'orcamento', 4, 'Granito Preto São Gabriel', 'Bisotado', '{"largura": 3.00, "altura": 0.65, "espessura": 0.03, "formato": "U"}', 4500.00, now() - interval '2 days', current_date + 20),

-- OS #5: Recebido (Inactive 6 days -> Delayed state badge)
('d5b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 5, 'd5e6f7a8-b9c0-1d2e-3f4a-5b6c7d8e9f0a', 'Painel de TV Sala', 'recebido', 5, 'Mármore Travertino', '45 Graus', '{"largura": 2.00, "altura": 1.20, "espessura": 0.02, "formato": "Reto"}', 6200.00, now() - interval '6 days', current_date + 12),

-- OS #6: Montagem (Active, assigned)
('d6b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 6, 'f1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'Ilha Cozinha Central', 'montagem', 6, 'Quartzo Branco Estelar', 'Bisotado', '{"largura": 2.00, "altura": 1.00, "espessura": 0.03, "formato": "Reto"}', 5100.00, now() - interval '1 day', current_date + 5),

-- OS #7: Entrega (Completed, active delivery stage)
('d7b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 7, 'a2b3c4d5-e6f7-8a9b-0c1d-2e3f4a5b6c7d', 'Revestimento Lareira', 'entrega', 7, 'Mármore Carrara', '45 Graus', '{"largura": 1.80, "altura": 1.50, "espessura": 0.02, "formato": "Reto"}', 12000.00, now() - interval '5 days', current_date - 1)
ON CONFLICT (id) DO NOTHING;

-- 6. Seed Order Assignments (Assign employees to stages matching role constraints)
INSERT INTO public.order_assignments (id, order_id, stage, employee_id, assigned_at) VALUES
('b1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'corte', 'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f', now() - interval '1 day'),
('b2a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd3b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'corte', 'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f', now() - interval '2 hours'),
('b3a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd6b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'montagem', 'd4e5f6a7-b8c9-0d1e-2f3a-4b5c6d7e8f9a', now() - interval '1 day'),
('b4a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd7b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'entrega', 'e5f6a7b8-c9d0-1e2f-3a4b-5c6d7e8f9a0b', now() - interval '5 days')
ON CONFLICT (id) DO NOTHING;

-- 7. Seed Status History (Audit trail of status transitions matching current order status)
INSERT INTO public.status_history (id, order_id, from_status, to_status, changed_by, changed_at, notes) VALUES
-- OS 1 transitions
('h1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', NULL, 'orcamento', 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', now() - interval '10 days', 'Orçamento inicial criado.'),
('h1b2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'orcamento', 'aprovado', 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', now() - interval '8 days', 'Cliente aprovou o orçamento e efetuou sinal.'),
('h1c2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'aprovado', 'recebido', 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', now() - interval '7 days', 'Pedido recebido pelo financeiro e liberado para produção.'),
('h1d2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'recebido', 'esperando_material', 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', now() - interval '5 days', 'Aguardando chegada das chapas de Carrara.'),
('h1e2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'esperando_material', 'corte', 'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f', now() - interval '1 day', 'Material chegou. Iniciado o corte da bancada.'),

-- OS 2 transitions
('h2a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd2b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', NULL, 'orcamento', 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', now() - interval '12 days', 'Medições iniciais recebidas.'),
('h2b2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd2b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'orcamento', 'aprovado', 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', now() - interval '10 days', 'Aprovado pelo compras da construtora.'),
('h2c2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd2b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'aprovado', 'recebido', 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', now() - interval '8 days', 'Liberado produção.'),
('h2d2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd2b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'recebido', 'esperando_material', 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', now() - interval '4 days', 'Aguardando lote de Granito Preto São Gabriel do fornecedor.'),

-- OS 3 transitions
('h3a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd3b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', NULL, 'orcamento', 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', now() - interval '4 days', 'Criado orçamento.'),
('h3b2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd3b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'orcamento', 'aprovado', 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', now() - interval '3 days', 'Aprovado pelo cliente.'),
('h3c2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd3b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'aprovado', 'recebido', 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', now() - interval '2 days', 'Liberado.'),
('h3d2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd3b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'recebido', 'esperando_material', 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', now() - interval '1 day', 'Aguardando chapa branca.'),
('h3e2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd3b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'esperando_material', 'corte', 'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f', now() - interval '2 hours', 'Chapa disponível em estoque. Iniciado corte express.'),

-- OS 4 transitions
('h4a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd4b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', NULL, 'orcamento', 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', now() - interval '2 days', 'Aguardando retorno do cliente sobre o valor total.'),

-- OS 5 transitions
('h5a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd5b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', NULL, 'orcamento', 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', now() - interval '10 days', 'Orcamento feito.'),
('h5b2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd5b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'orcamento', 'aprovado', 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', now() - interval '8 days', 'Aprovado.'),
('h5c2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd5b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'aprovado', 'recebido', 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', now() - interval '6 days', 'Recebido financeiro. Sem novas movimentações desde então.'),

-- OS 6 transitions
('h6a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd6b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', NULL, 'orcamento', 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', now() - interval '15 days', 'Orcamento criado.'),
('h6b2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd6b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'orcamento', 'aprovado', 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', now() - interval '12 days', 'Aprovado.'),
('h6c2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd6b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'aprovado', 'recebido', 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', now() - interval '10 days', 'Recebido.'),
('h6d2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd6b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'recebido', 'esperando_material', 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', now() - interval '8 days', 'Aguardando quartzo.'),
('h6e2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd6b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'esperando_material', 'corte', 'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f', now() - interval '4 days', 'Corte finalizado das peças.'),
('h6f2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd6b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'corte', 'montagem', 'd4e5f6a7-b8c9-0d1e-2f3a-4b5c6d7e8f9a', now() - interval '1 day', 'Peças cortadas e lixadas. Iniciada montagem da saia de 45 graus.'),

-- OS 7 transitions
('h7a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd7b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', NULL, 'orcamento', 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', now() - interval '25 days', 'Orçamento.'),
('h7b2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd7b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'orcamento', 'aprovado', 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', now() - interval '22 days', 'Aprovado.'),
('h7c2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd7b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'aprovado', 'recebido', 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', now() - interval '20 days', 'Liberado.'),
('h7d2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd7b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'recebido', 'esperando_material', 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', now() - interval '18 days', 'Aguardando Carrara.'),
('h7e2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd7b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'esperando_material', 'corte', 'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f', now() - interval '12 days', 'Corte concluído.'),
('h7f2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd7b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'corte', 'montagem', 'd4e5f6a7-b8c9-0d1e-2f3a-4b5c6d7e8f9a', now() - interval '8 days', 'Montagem concluída.'),
('h7g2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'd7b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'montagem', 'entrega', 'e5f6a7b8-c9d0-1e2f-3a4b-5c6d7e8f9a0b', now() - interval '5 days', 'Liberado para a equipe de entrega levar à obra.')
ON CONFLICT (id) DO NOTHING;
