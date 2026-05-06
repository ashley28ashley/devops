import unittest
from main import generate_job_value

class TestMain(unittest.TestCase):
    def test_generate_job_value(self):
        """Test que la fonction retourne bien un entier entre 1 et 1000"""
        value = generate_job_value()
        self.assertIsInstance(value, int)
        self.assertTrue(1 <= value <= 1000)

if __name__ == '__main__':
    unittest.main()
