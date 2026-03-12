workspace "Мессенджер" "Описание архитектуры мессенджера" {
    model {
        user = person "Пользователь" "Зарегистрированный пользователь мессенджера"
        
        notificationService = softwareSystem "Сервис уведомлений" "Внешний сервис для отправки push/email" {
            tags "external"
        }
        
        messenger = softwareSystem "Мессенджер" "Система обмена сообщениями" {
            webApp = container "Веб-приложение" "React-приложение, интерфейс пользователя" "React"
            apiServer = container "API-сервер" "Обрабатывает HTTP-запросы, бизнес-логика" "Node.js + Express"
            wsServer = container "WebSocket-сервер" "Обеспечивает real-time доставку сообщений" "Socket.io"
            database = container "База данных" "Хранит данные о пользователях, чатах, сообщениях" "PostgreSQL"
            searchService = container "Поисковый сервис" "Индексирует пользователей для поиска по имени/фамилии" "Elasticsearch"
        }
        
        webApp -> apiServer "Вызывает API (создание пользователя, поиск, создание чата)" "HTTPS/REST"
        webApp -> wsServer "Устанавливает WebSocket-соединение для получения/отправки сообщений" "WebSocket"
        apiServer -> database "Читает/записывает данные" "JDBC"
        apiServer -> searchService "Выполняет поиск пользователей" "HTTP/REST"
        wsServer -> database "Проверяет права доступа и сохраняет сообщения (опционально)" "JDBC"
        wsServer -> notificationService "Вызывает внешний сервис для уведомлений (если адресат офлайн)" "HTTPS/REST"
        apiServer -> notificationService "Отправляет уведомления (например, о новом сообщении)" "HTTPS/REST"
        user -> webApp "Использует"
        user -> wsServer "Использует (через WebSocket)"
    }
    
    views {
        themes default 

        systemcontext messenger "SystemContext" "Диаграмма контекста системы" {
            include user
            include notificationService
            autolayout lr
        }
        
        container messenger "Container" "Диаграмма контейнеров" {
            include user
            include webApp
            include apiServer
            include wsServer
            include database
            include searchService
            include notificationService
            autolayout lr
        }
        
        dynamic messenger "SendPersonalMessage" "Диаграмма динамики для сценария отправки сообщения между пользователями" {
            autolayout lr
            user -> webApp "Пишет сообщение и нажимает отправить"
            webApp -> apiServer "POST /api/messages (сохранить сообщение)"
            apiServer -> database "INSERT INTO ptp_messages"
            apiServer -> webApp "Ответ: сообщение сохранено"
        
            webApp -> wsServer "Передаёт сообщение для доставки получателю"
            wsServer -> database "Проверяет статус получателя (онлайн/офлайн)"
            wsServer -> user "[Если онлайн] Отправляет сообщение через WebSocket"
    
            wsServer -> notificationService "[Если офлайн] Запрос на отправку push-уведомления"
            notificationService -> wsServer "Уведомление отправлено"
    
        }

        styles {
            element "softwareSystem" {
                background #1168bd
                color #ffffff
            }
            element "person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "external" {
                background #999999
            }
            element "container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}