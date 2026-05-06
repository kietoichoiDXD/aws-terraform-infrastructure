#!/bin/bash
# ==============================================================================
# SCRIPT: check.sh
# CHỨC NĂNG: Kiểm tra nhanh cú pháp và format của toàn bộ code Terraform.
# CÁCH DÙNG: ./scripts/check.sh
# ==============================================================================

echo "🔍 Đang kiểm tra định dạng code (terraform fmt)..."
terraform fmt -recursive

echo "🔍 Đang kiểm tra cú pháp (terraform validate)..."
cd infrastructure/environments/dev
terraform validate

if [ $? -eq 0 ]; then
    echo "✅ Code của bạn chuẩn không cần chỉnh!"
else
    echo "❌ Có lỗi cú pháp, vui lòng kiểm tra lại."
fi
