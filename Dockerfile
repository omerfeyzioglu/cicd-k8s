# Dockerfile
# --- Stage 1: Build the application JAR ---
# Build aşaması için JDK ve Maven içeren bir base image kullanalım
FROM maven:3.8.5-openjdk-17 AS builder

# Çalışma dizini
WORKDIR /workspace/app

# Önce sadece pom.xml'i kopyala (dependency katmanını cachelemek için)
COPY pom.xml .

# Maven bağımlılıklarını indir
RUN mvn dependency:go-offline -B

# Tüm proje kaynak kodunu kopyala
COPY src ./src

# Uygulamayı derle ve JAR paketini oluştur (testleri atla)
# Proje adınız ve versiyonunuza göre JAR adı değişebilir, *.jar genel bir ifadedir.
RUN mvn package -DskipTests

# --- Stage 2: Create the final lightweight application image ---
# Sonuç imajı için sadece JRE içeren küçük bir base image kullanalım
FROM openjdk:17-jre-slim

# Çalışma dizini
WORKDIR /app

# İlk aşamada ('builder') oluşturulan JAR dosyasını kopyala
# JAR dosyasının adının doğru olduğundan emin olun (genellikle target/*.jar)
COPY --from=builder /workspace/app/target/*.jar application.jar

# Uygulamanın çalışacağı port (Spring Boot varsayılan olarak 8080 kullanır)
EXPOSE 8081

# Konteyner başladığında uygulamayı çalıştıracak komut
ENTRYPOINT ["java","-jar","/app/application.jar"]
