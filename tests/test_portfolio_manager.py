
import unittest
from unittest.mock import MagicMock, patch

from financial_advisor.sub_agents.portfolio_manager.agent import PortfolioManagerAgent

class TestPortfolioManagerAgent(unittest.TestCase):
    @patch("financial_advisor.connectors.ibkr_connector.get_ibkr_portfolio")
    @patch("financial_advisor.connectors.gcp_sql_connector.get_gcp_sql_engine")
    @patch("financial_advisor.connectors.gcp_sql_connector.create_portfolio_table")
    @patch("financial_advisor.connectors.gcp_sql_connector.upsert_portfolio")
    def test_update_portfolio(self, mock_upsert_portfolio, mock_create_portfolio_table, mock_get_gcp_sql_engine, mock_get_ibkr_portfolio):
        # Arrange
        mock_get_ibkr_portfolio.return_value = [{"symbol": "AAPL", "quantity": 100}]
        mock_engine = MagicMock()
        mock_get_gcp_sql_engine.return_value = mock_engine
        agent = PortfolioManagerAgent()

        # Act
        result = agent.update_portfolio()

        # Assert
        mock_get_ibkr_portfolio.assert_called_once()
        mock_get_gcp_sql_engine.assert_called_once()
        mock_create_portfolio_table.assert_called_once_with(mock_engine)
        mock_upsert_portfolio.assert_called_once_with(mock_engine, [{"symbol": "AAPL", "quantity": 100}])
        self.assertEqual(result, "Portfolio updated successfully.")

if __name__ == "__main__":
    unittest.main()
