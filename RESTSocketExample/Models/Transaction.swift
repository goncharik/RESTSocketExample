import Foundation

struct BitcoinTransactionResponse: Codable {
    let op: String
    let x: BitcoinTransactionDetails
}

struct BitcoinTransactionDetails: Codable, Hashable, Identifiable {
    let lockTime: Int
    let ver: Int
    let size: Int
    let inputs: [BitcoinInput]
    let time: TimeInterval
    let txIndex: Int
    let vinSz: Int
    let hash: String
    let voutSz: Int
    let relayedBy: String
    let out: [BitcoinOutput]

    var id: String { hash }

    var btcAmount: Double {
        // Calculate the transaction amount by summing the unspent output values
        let unspentOutputs = out.filter { !$0.spent }
        let transactionAmount = unspentOutputs.reduce(0) { $0 + $1.value }

        // Convert Satoshi to Bitcoin (1 Bitcoin = 100,000,000 Satoshi)
        let transactionAmountInBitcoin = Double(transactionAmount) / 100_000_000

        return transactionAmountInBitcoin
    }
}

struct BitcoinInput: Codable, Hashable {
    let sequence: Int
    let prevOut: BitcoinPreviousOutput
    let script: String
}

struct BitcoinPreviousOutput: Codable, Hashable {
    let spent: Bool
    let txIndex: Int
    let type: Int
    let addr: String
    let value: Int
    let n: Int
    let script: String
}

struct BitcoinOutput: Codable, Hashable {
    let spent: Bool
    let txIndex: Int
    let type: Int
    let addr: String
    let value: Int
    let n: Int
    let script: String
}
