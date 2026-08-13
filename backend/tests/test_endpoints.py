import asyncio
import httpx

async def main():
    async with httpx.AsyncClient(base_url="http://127.0.0.1:8000") as client:
        # Register
        print("Testing Register...")
        reg_res = await client.post("/api/v1/auth/register", json={"email": "test456@example.com", "password": "password"})
        print("Register:", reg_res.status_code, reg_res.text)
        
        # Login
        print("Testing Login...")
        log_res = await client.post("/api/v1/auth/login", json={"email": "test456@example.com", "password": "password"})
        print("Login:", log_res.status_code, log_res.text)
        
        if log_res.status_code == 200:
            token = log_res.json()["access_token"]
            
            # Upload CSV
            print("Testing Upload...")
            try:
                with open("sample_hdfc.csv", "rb") as f:
                    upload_res = await client.post("/api/v1/upload/statement", files={"file": ("sample_hdfc.csv", f, "text/csv")}, headers={"Authorization": f"Bearer {token}"})
                    print("Upload:", upload_res.status_code, upload_res.text)
            except Exception as e:
                print(e)
            
if __name__ == "__main__":
    asyncio.run(main())