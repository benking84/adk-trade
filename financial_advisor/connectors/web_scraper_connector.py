
import requests
from bs4 import BeautifulSoup

def get_insider_trades():
    """Scrapes the OpenInsider website for the latest insider trades."""
    url = "http://openinsider.com/latest-insider-buys"
    response = requests.get(url)
    soup = BeautifulSoup(response.content, "html.parser")

    trades = []
    table = soup.find("table", {"class": "tinytable"})
    if table:
        for row in table.find_all("tr")[1:]:
            cells = row.find_all("td")
            if len(cells) == 13:
                trade = {
                    "ticker": cells[3].text.strip(),
                    "insider_name": cells[5].text.strip(),
                    "relationship": cells[6].text.strip(),
                    "transaction_date": cells[2].text.strip(),
                    "transaction_type": cells[7].text.strip(),
                    "transaction_value": cells[9].text.strip().replace(",", ""),
                    "shares": cells[8].text.strip().replace(",", ""),
                    "price_per_share": cells[10].text.strip(),
                }
                trades.append(trade)
    return trades

if __name__ == "__main__":
    # For testing purposes
    insider_trades = get_insider_trades()
    print("Insider Trades:")
    print(insider_trades)
