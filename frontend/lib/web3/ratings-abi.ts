export const ORBITWORK_RATINGS_ABI = [
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "_secureFlow",
                "type": "address"
            }
        ],
        "stateMutability": "nonpayable",
        "type": "constructor"
    },
    {
        "anonymous": false,
        "inputs": [
            {
                "indexed": true,
                "internalType": "address",
                "name": "rater",
                "type": "address"
            },
            {
                "indexed": true,
                "internalType": "address",
                "name": "rated",
                "type": "address"
            },
            {
                "indexed": false,
                "internalType": "uint256",
                "name": "escrowId",
                "type": "uint256"
            },
            {
                "indexed": false,
                "internalType": "uint8",
                "name": "score",
                "type": "uint8"
            }
        ],
        "name": "RatingSubmitted",
        "type": "event"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "user",
                "type": "address"
            }
        ],
        "name": "getAverageRating",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "user",
                "type": "address"
            }
        ],
        "name": "getRatingCount",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "user",
                "type": "address"
            }
        ],
        "name": "getRatings",
        "outputs": [
            {
                "components": [
                    {
                        "internalType": "uint256",
                        "name": "escrowId",
                        "type": "uint256"
                    },
                    {
                        "internalType": "address",
                        "name": "rater",
                        "type": "address"
                    },
                    {
                        "internalType": "address",
                        "name": "rated",
                        "type": "address"
                    },
                    {
                        "internalType": "uint8",
                        "name": "score",
                        "type": "uint8"
                    },
                    {
                        "internalType": "string",
                        "name": "comment",
                        "type": "string"
                    },
                    {
                        "internalType": "uint256",
                        "name": "timestamp",
                        "type": "uint256"
                    }
                ],
                "internalType": "struct OrbitworkRatings.Rating[]",
                "name": "",
                "type": "tuple[]"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            },
            {
                "internalType": "address",
                "name": "",
                "type": "address"
            }
        ],
        "name": "hasRated",
        "outputs": [
            {
                "internalType": "bool",
                "name": "",
                "type": "bool"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "uint256",
                "name": "escrowId",
                "type": "uint256"
            },
            {
                "internalType": "uint8",
                "name": "score",
                "type": "uint8"
            },
            {
                "internalType": "string",
                "name": "comment",
                "type": "string"
            }
        ],
        "name": "rateTransaction",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "name": "ratings",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "escrowId",
                "type": "uint256"
            },
            {
                "internalType": "address",
                "name": "rater",
                "type": "address"
            },
            {
                "internalType": "address",
                "name": "rated",
                "type": "address"
            },
            {
                "internalType": "uint8",
                "name": "score",
                "type": "uint8"
            },
            {
                "internalType": "string",
                "name": "comment",
                "type": "string"
            },
            {
                "internalType": "uint256",
                "name": "timestamp",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "secureFlow",
        "outputs": [
            {
                "internalType": "contract IOrbitWork",
                "name": "",
                "type": "address"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    }
] as const;
