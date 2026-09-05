# Инфраструктура как код

[![hexlet-check](https://github.com/kimdeun/devops-engineer-from-scratch-project-77/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/kimdeun/devops-engineer-from-scratch-project-77/actions)

Terraform создаёт в Yandex Cloud два веб-сервера и Application Load Balancer с HTTPS. Приложение доступно по адресу [https://hexlet-project-77.duckdns.org](https://hexlet-project-77.duckdns.org). Ansible устанавливает Docker и запускает на обеих машинах контейнер `nginxdemos/hello`. Приложение не использует базу данных, поэтому управляемая БД не создаётся.

## Что создаётся

- сеть, подсеть и отдельные security groups для ALB и серверов;
- две прерываемые Ubuntu VM с публичными адресами для Ansible;
- target group, HTTP backend group/router и L7-балансировщик;
- HTTPS listener на порту 443 с сертификатом из Certificate Manager;
- удалённый S3 backend в Yandex Object Storage;
- Datadog Agent на каждой VM и Terraform-managed alert локальной HTTP-проверки.
- Upmon heartbeat публичного HTTPS-адреса с email-уведомлениями.

Стейт, сгенерированные секреты и backend-конфигурация исключены из Git.

## Требования

- Terraform 1.6 или новее;
- Ansible;
- Yandex Cloud CLI (`yc`), авторизованный командой `yc init`;
- аккаунт и каталог Yandex Cloud;
- бакет Object Storage и статический ключ сервисного аккаунта с доступом к нему;
- SSH-ключ;
- аккаунт Datadog, API key и Application key.

## Подготовка секретов

Установите коллекции и создайте локальный файл с паролем Vault:

```bash
make install
printf '%s\n' 'сильный-пароль' > ansible/.vault_password
chmod 600 ansible/.vault_password
```

Файл `ansible/vault.example.yml` служит только списком необходимых переменных.
Не записывайте в него настоящие секреты, поскольку файл хранится в Git. Для
создания Vault подготовьте игнорируемую локальную копию:

```bash
cp ansible/vault.example.yml ansible/vault.local.yml
# заполните ansible/vault.local.yml настоящими значениями
make vault-create
```

`make vault-create` шифрует `ansible/vault.local.yml` в `ansible/vault.yml`.
Оба локальных файла с открытыми данными (`vault.local.yml` и `.vault_password`)
исключены из Git. Уже созданный зашифрованный Vault изменяется командой:

```bash
make vault-edit
```

Terraform обновляет A-запись DuckDNS и получает публичный сертификат Let’s Encrypt через DNS challenge, после чего загружает его в Certificate Manager. Ограничьте `vault_ssh_allowed_cidrs` своим внешним адресом `/32`.

Команда ниже расшифровывает Vault средствами Ansible и создаёт два игнорируемых файла: `terraform/secrets.auto.tfvars` и `terraform/backend.hcl`.

```bash
make secrets
```

Terraform сам Vault не расшифровывает.

## Создание инфраструктуры

```bash
make init
make fmt
make validate
make plan
make apply
make output
```

Для проверки конфигурации без доступа к backend и Yandex Cloud:

```bash
terraform -chdir=terraform init -backend=false
terraform -chdir=terraform validate
```

`make plan` сохраняет проверенный план, а `make apply` применяет именно его. Не прерывайте выполняющийся `apply` или `destroy`: сначала дождитесь завершения операции либо корректно отмените её.

## Деплой

Инвентори `ansible/inventory.py` получает IP машин из Terraform output. Приватный
SSH-ключ используется стандартным SSH agent либо задаётся через переменную:

```bash
export ANSIBLE_PRIVATE_KEY_FILE="$HOME/.ssh/id_ed25519"
```

```bash
make ping
make prepare
make deploy
make monitoring
make uptime
curl https://hexlet-project-77.duckdns.org/
```

`make monitoring` устанавливает Datadog Agent на обе VM и настраивает проверку
`http://localhost/`. Terraform создаёт service-check monitor, который переходит в
критическое состояние после двух неуспешных проверок. Ключи Datadog находятся в
зашифрованном `ansible/vault.yml` и не сохраняются в открытом виде в репозитории.

`make uptime` устанавливает на обе VM systemd timer. Каждые пять минут сервер
проверяет публичный HTTPS-адрес приложения и только после успешного ответа
отправляет heartbeat в Upmon. Уникальный `vault_upmon_ping_url` хранится в Vault.

Для полного запуска плейбука без фильтра тегов:

```bash
cd ansible && ansible-playbook playbook.yml --vault-password-file .vault_password
```

## Удаление

```bash
make destroy
```

После удаления ресурсов удалённый state остаётся в Object Storage. Локальные сгенерированные файлы можно удалить командой `make clean-generated`.

## О Хекслете

[Хекслет](https://ru.hexlet.io/) — школа разработки и DevOps с практическими проектами.
