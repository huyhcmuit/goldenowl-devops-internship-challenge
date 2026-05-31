# Stage 1: Build & Test
FROM node:18-alpine AS builder

WORKDIR /app/src

# Copy package.json trước để tận dụng Docker Cache, giúp build nhanh hơn ở các lần sau
COPY src/package*.json ./
RUN npm ci

# Copy toàn bộ mã nguồn vào
COPY src/ .

# Chạy test ngay trong lúc build. Nếu test fail, Docker sẽ dừng build ngay lập tức.
RUN npm test

# ========================================== #

# Stage 2: Production Image 
FROM node:18-alpine AS production

WORKDIR /app/src

# Thiết lập biến môi trường là production để Node.js tối ưu hiệu suất
ENV NODE_ENV=production

# Chỉ copy package.json từ Stage 1 sang
COPY --from=builder /app/src/package*.json ./

# Cài đặt CÁC THƯ VIỆN CẦN THIẾT CHO PRODUCTION 
# Giúp giảm tối đa dung lượng image và hạn chế lỗ hổng bảo mật
RUN npm ci --omit=dev

# Copy mã nguồn đã vượt qua bài test từ Stage 1 sang
COPY --from=builder /app/src/ .

# Bảo mật nâng cao: Không chạy app bằng quyền root. 
# Sử dụng user 'node' có sẵn trong base image alpine.
USER node

# Mở port 3000 để giao tiếp với bên ngoài
EXPOSE 3000

# Lệnh khởi chạy ứng dụng
CMD ["npm", "start"]