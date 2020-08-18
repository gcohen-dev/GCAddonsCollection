//
//  File.swift
//  
//
//  Created by Guy Cohen on 18/08/2020.
//

import Foundation

/**
 An example for API request
 1.) First have an enum similar to here
 
 enum CustomerApi {
     case get(phone: String)
     case set(customer: CustomerGetResponse)
     
     var urlRequest: URLRequest? {
         guard let url = self.url else { return nil }
         switch self {
         case .get(phone: let phone):
             var urlRequest = URLRequest(url: url)
             urlRequest.httpMethod = "POST"
             let dictionaryBody = [ "tworkxftela": "\(phone)"]
             guard let dataJson = try? JSONSerialization.data(withJSONObject: dictionaryBody, options: []) else {
                 return nil
             }
             urlRequest.httpBody = dataJson
             return urlRequest
         case .set(customer: let customer):
             var urlRequest = URLRequest(url: url)
             urlRequest.httpMethod = "POST"
             guard let dictionaryCodable = try? customer.generatePostRequest().toDictionary() else { return nil }
             guard let dataJson = try? JSONSerialization.data(withJSONObject: dictionaryCodable, options: []) else {
                 return nil
             }
             urlRequest.httpBody = dataJson
             return urlRequest
         }
     }
     
     private var url: URL? {
         switch self {
         case .set(customer: _):
             return URL(string: baseURL + "setCustomerData")
         case .get(phone: _):
             return URL(string: baseURL + "getCustomerData")
         }
     }
 }
 
 2.) second run the request
 guard let getCustomerRequest = CustomerApi.get(phone: model.contact.phone).urlRequest else { return }
 let getCustomerPublished: AnyPublisher<[CustomerGetResponse], Error> = network.run(getCustomerRequest)
 let firstCustomer = getCustomerPublished.compactMap{ $0.first }
 /// First request
 let setCustomer = firstCustomer.flatMap { customerResponse -> AnyPublisher<CustomerSetResponse, Error> in
     let setRequest = CustomerApi.set(customer: customerResponse).urlRequest!
     return self.network.run(setRequest) // run second request
 }
 // second result trigger the first one
 setCustomer.receive(on: DispatchQueue.main).sink(receiveCompletion: { (error) in
     if case .failure(let errorDescription) = error {
         print(errorDescription.localizedDescription)
     }
 }) { (customerSetResponse) in
     switch customerSetResponse.responseResult {
     case .insert: break // TODO: insert has been done //
     case .update: break // TODO: update success // TODO update firebase that order is verified
     case .notSent: break // Not send error
     case .unknown: break // unknown error
     }
 }
 .store(in: &bindings)
 
 break
}
 
 */

struct GCNetworkAgent {
    
    enum APIError: Error, LocalizedError {
        case unknown
        case apiError(reason: String)
        case parserError(reason: String)
        case zeroElement
        case networkError(from: URLError)

        var errorDescription: String? {
            switch self {
            case .unknown:
                return "Unknown error"
            case .apiError(let reason), .parserError(let reason):
                return reason
            case .networkError(let from):
                return from.localizedDescription
            case .zeroElement:
                return "Zero elements in array"
            }
        }
    }
    
    func run<T: Decodable>(_ request: URLRequest, _ decoder: JSONDecoder = JSONDecoder()) -> AnyPublisher<T, Error> {
        return URLSession.shared
            .dataTaskPublisher(for: request)
            .tryMap { (data, response) -> T in
                guard let httpResponse = response as? HTTPURLResponse else { throw APIError.unknown}
                if (httpResponse.statusCode == 401) { throw APIError.apiError(reason: "Unauthorized:\(httpResponse.statusCode)") }
                if (httpResponse.statusCode == 403) { throw APIError.apiError(reason: "Resource forbidden:\(httpResponse.statusCode)") }
                if (httpResponse.statusCode == 404) { throw APIError.apiError(reason: "Resource not found:\(httpResponse.statusCode)") }
                if (405..<500 ~= httpResponse.statusCode) { throw APIError.apiError(reason: "Client Error:\(httpResponse.statusCode)") }
                if (500..<600 ~= httpResponse.statusCode) { throw APIError.apiError(reason: "Server Error:\(httpResponse.statusCode)") }
                guard httpResponse.statusCode == 200 else { throw APIError.apiError(reason: "Status code not handled \(httpResponse.statusCode)") }
                do {
                    let value = try decoder.decode(T.self, from: data)
                    if let valueArray = value as? Array<T>, valueArray.count == 0 { throw APIError.zeroElement }
                    return value
                } catch(let error) {
                    throw APIError.parserError(reason: "Parse error: \(error.localizedDescription)")
                }
            }
            .eraseToAnyPublisher()
    }
}

