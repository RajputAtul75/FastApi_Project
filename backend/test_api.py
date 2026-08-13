import requests

base_url = "http://127.0.0.1:8000/api"

print("--- Testing API ---")
res = requests.get(f"{base_url}/health")
print("Health:", res.json())

res = requests.post(f"{base_url}/seed")
print("Seed:", res.json())

payload = {
    "title": "Broken pipe in downtown",
    "description": "There is a massive water leak from a broken pipe near the library.",
    "location": "Downtown Library",
    "category": None
}
res = requests.post(f"{base_url}/grievances", json=payload)
data = res.json()
print("Create Grievance:", data)

if "ticket_id" in data:
    ticket_id = data["ticket_id"]
    res = requests.put(f"{base_url}/grievances/{ticket_id}/status", json={"status": "In Progress"})
    print("Update Status:", res.json())
    
    res = requests.put(f"{base_url}/grievances/{ticket_id}/department", json={"department": "Water Department"})
    print("Update Department:", res.json())

res = requests.get(f"{base_url}/dashboard/stats")
print("Dashboard Stats:", res.json())
