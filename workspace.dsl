workspace "Messenger System" "Мессенджер" {

    model {
        user = person "Пользователь" "Отправляет сообщения, создает чаты и общается" "Person"
        admin = person "Администратор" "Управляет системой" "Person"

        pushSystem = softwareSystem "Push Notification Service" "Отправка push-уведомлений" "External"
        emailSystem = softwareSystem "Email Service" "Отправка email уведомлений" "External"

        messenger = softwareSystem "Messenger System" {

            gateway = container "API Gateway" "REST + WebSocket: маршрутизация, auth, realtime соединения" "Nginx + WebSocket" "Container"

            userService = container "User Service" "Регистрация, поиск пользователей" "C++/Userver" "Container"
            chatService = container "Chat Service" "Управление чатами (групповые и PtP)" "C++/Userver" "Container"
            messageService = container "Message Service" "Отправка и получение сообщений" "C++/Userver" "Container"
            notificationService = container "Notification Service" "Генерация уведомлений" "C++/Userver" "Container"

            userDb = container "User Database" "Хранение пользователей" "PostgreSQL" "Database"
            chatDb = container "Chat Database" "Хранение чатов" "PostgreSQL" "Database"
            messageDb = container "Message Database" "Хранение сообщений" "PostgreSQL" "Database"

            cache = container "Cache" "Кэш сообщений и пользователей" "Redis" "Database"

            broker = container "Message Broker" "Очередь сообщений" "Kafka/RabbitMQ" "Broker"
        }

        user -> gateway "REST API (регистрация, чаты, сообщения)" "HTTPS/JSON"
        user -> gateway "Realtime сообщения" "WebSocket (WSS)"

        admin -> gateway "Администрирование" "HTTPS/JSON"

        gateway -> userService "REST запросы" "HTTP/JSON"
        gateway -> chatService "REST запросы" "HTTP/JSON"
        gateway -> messageService "REST запросы" "HTTP/JSON"

        gateway -> messageService "Передача realtime сообщений" "WebSocket"

        userService -> userDb "CRUD пользователей" "TCP/SQL"
        userService -> cache "Кэш пользователей" "TCP"

        chatService -> chatDb "CRUD чатов" "TCP/SQL"
        chatService -> userService "Проверка пользователей" "HTTP/JSON"
        chatService -> cache "Кэш чатов" "TCP"

        messageService -> messageDb "Сохранение сообщений" "TCP/SQL"
        messageService -> chatService "Проверка чата" "HTTP/JSON"
        messageService -> broker "Публикация событий" "TCP"
        messageService -> cache "Кэш сообщений" "TCP"

        broker -> notificationService "События новых сообщений" "TCP"

        notificationService -> pushSystem "Push уведомления" "HTTPS"
        notificationService -> emailSystem "Email уведомления" "SMTP"
    }

    views {
        systemContext messenger "SystemContext" {
            include *
            autolayout lr
        }

        container messenger "ContainerView" {
            include *
            autolayout lr
        }

        dynamic messenger "SendMessageUseCase" {
            
            user -> gateway "Отправка сообщения (WebSocket)"
            gateway -> messageService "Передача сообщения"
            messageService -> chatService "Проверка чата"
            chatService -> userService "Проверка участников чата"
            messageService -> messageDb "Сохранение сообщения"
            messageService -> cache "Обновление кэша сообщений"
            messageService -> broker "Публикация события"
            broker -> notificationService "Новое сообщение"
            notificationService -> pushSystem "Push уведомление"
            notificationService -> emailSystem "Email уведомление"
            messageService -> gateway "ACK сообщение доставлено"
            gateway -> user "Сообщение доставлено"
            autolayout lr
        }

        styles {
            element "Database" {
                shape Cylinder
                background #1168bd
                color #ffffff
            }
            element "Broker" {
                shape Pipe
                background #d35400
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}