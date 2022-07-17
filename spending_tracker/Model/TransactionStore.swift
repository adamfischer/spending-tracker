import UIKit

private let kFetchTransactionsURL = "https://development.sprintform.com/transactions.json"

// Fetches and caches Transactions. Does not persist them between application runs.
class TransactionStore {
    private var transactions : Array<Transaction>? = nil
    
    static let shared = TransactionStore()

    private init(){}
    
    private func parse(jsonData: Data) -> Result<[Transaction],Error>{
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            let transactions: [Transaction] = try decoder.decode([Transaction].self,
                                                                 from: jsonData)
            return .success(transactions)
        } catch {
            return .failure(error)
        }
    }
    
    private func loadJson(fromURLString urlString: String,
                          completion: @escaping (Result<Data, Error>) -> Void) {
        if let url = URL(string: urlString) {
            let urlSession = URLSession(configuration: .default).dataTask(with: url, completionHandler:{ (data, response, error) in
                if let error = error {
                    completion(.failure(error))
                }
                else if let data = data {
                    completion(.success(data))
                }
                else {
                    let error = SpendingTrackerError.NoDataReceived
                    completion(.failure(error))
                }
            })
            
            urlSession.resume()
        }
    }
    
    public func fetchTransactions(completion: @escaping (Result<[Transaction], Error>) -> Void) {
        if let transactions = self.transactions {
            completion(.success(transactions))
        }
        else {
            loadJson(fromURLString: kFetchTransactionsURL, completion: { (result) in
                switch result {
                case .success(let data):
                    //sleep(5) // To test activity indicators.

                    let parseResults : Result<[Transaction],Error> = self.parse(jsonData: data)
                    switch parseResults {
                    case .success(let transactions):
                        print("Fetching transactions successful: \(transactions)")

                        DispatchQueue.main.async {
                            self.transactions = transactions // Cache transactions.
                            completion(.success(transactions))
                        }
                    case .failure(let error):
                        // Parsing failed.
                        completion(.failure(error))
                    }
                case .failure(let error):
                    // Download failed.
                    completion(.failure(error))
                }
            })
        }
    }
}
