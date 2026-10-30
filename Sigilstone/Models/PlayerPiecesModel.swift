//
//  PlayerPiecesModel.swift
//  Sigilstone
//
//  Created by Nicholas Rebello on 2024-11-18.
//

import Foundation

class PlayerPiecesModel: ObservableObject {
    @Published var player1Pieces: [Stone] = [
        Stone(top: 3, right: 2, bottom: 3, left: 2, owner: 1),
        Stone(top: 2, right: 3, bottom: 2, left: 3, owner: 1),
        Stone(top: 4, right: 1, bottom: 3, left: 2, owner: 1),
        Stone(top: 2, right: 4, bottom: 2, left: 3, owner: 1),
        Stone(top: 3, right: 3, bottom: 2, left: 3, owner: 1)
    ]
    @Published var player2Pieces: [Stone] = [
        Stone(top: 3, right: 2, bottom: 3, left: 2, owner: 2),
        Stone(top: 2, right: 3, bottom: 2, left: 3, owner: 2),
        Stone(top: 4, right: 1, bottom: 3, left: 2, owner: 2),
        Stone(top: 2, right: 4, bottom: 2, left: 3, owner: 2),
        Stone(top: 3, right: 3, bottom: 2, left: 3, owner: 2)
    ]
    @Published var level1Pieces: [Stone] = [
        Stone(top: 1, right: 0, bottom: 1, left: 2, owner: 2),
        Stone(top: 1, right: 1, bottom: 0, left: 2, owner: 2),
        Stone(top: 0, right: 2, bottom: 1, left: 1, owner: 2),
        Stone(top: 1, right: 1, bottom: 2, left: 0, owner: 2),
        Stone(top: 2, right: 0, bottom: 1, left: 1, owner: 2)
    ]
    @Published var level2Pieces: [Stone] = [
        Stone(top: 2, right: 1, bottom: 2, left: 2, owner: 2),
        Stone(top: 2, right: 2, bottom: 1, left: 2, owner: 2),
        Stone(top: 1, right: 3, bottom: 2, left: 1, owner: 2),
        Stone(top: 2, right: 2, bottom: 2, left: 1, owner: 2),
        Stone(top: 3, right: 1, bottom: 2, left: 2, owner: 2)
    ]
    @Published var level3Pieces: [Stone] = [
        Stone(top: 3, right: 2, bottom: 3, left: 1, owner: 2),
        Stone(top: 2, right: 3, bottom: 1, left: 3, owner: 2),
        Stone(top: 3, right: 3, bottom: 2, left: 1, owner: 2),
        Stone(top: 4, right: 3, bottom: 3, left: 2, owner: 2),
        Stone(top: 2, right: 4, bottom: 3, left: 2, owner: 2)
    ]
    @Published var level4Pieces: [Stone] = [
        Stone(top: 3, right: 4, bottom: 2, left: 3, owner: 2),
        Stone(top: 4, right: 3, bottom: 4, left: 1, owner: 2),
        Stone(top: 3, right: 4, bottom: 3, left: 2, owner: 2),
        Stone(top: 4, right: 2, bottom: 3, left: 4, owner: 2),
        Stone(top: 3, right: 3, bottom: 4, left: 3, owner: 2)
    ]
    @Published var level5Pieces: [Stone] = [
        Stone(top: 3, right: 4, bottom: 3, left: 4, owner: 2),
        Stone(top: 4, right: 2, bottom: 4, left: 3, owner: 2),
        Stone(top: 3, right: 4, bottom: 2, left: 4, owner: 2),
        Stone(top: 0, right: 3, bottom: 4, left: 4, owner: 2),
        Stone(top: 4, right: 4, bottom: 2, left: 4, owner: 2)
    ]
    @Published var level6Pieces: [Stone] = [
        Stone(top: 3, right: 3, bottom: 3, left: 4, owner: 2),
        Stone(top: 3, right: 4, bottom: 5, left: 3, owner: 2),
        Stone(top: 4, right: 4, bottom: 4, left: 4, owner: 2),
        Stone(top: 5, right: 3, bottom: 3, left: 3, owner: 2),
        Stone(top: 3, right: 4, bottom: 4, left: 4, owner: 2),
    ]
    
    @Published var player1PiecesForEachDifficulty: [[Stone]] = [
        [Stone(top: 1, right: 2, bottom: 1, left: 0, owner: 1),
         Stone(top: 2, right: 1, bottom: 2, left: 0, owner: 1),
         Stone(top: 1, right: 3, bottom: 0, left: 1, owner: 1),
         Stone(top: 2, right: 2, bottom: 1, left: 1, owner: 1),
         Stone(top: 1, right: 2, bottom: 1, left: 2, owner: 1)
        ],
        [Stone(top: 2, right: 3, bottom: 1, left: 2, owner: 1),
         Stone(top: 3, right: 2, bottom: 1, left: 1, owner: 1),
         Stone(top: 2, right: 2, bottom: 2, left: 0, owner: 1),
         Stone(top: 1, right: 3, bottom: 3, left: 1, owner: 1),
         Stone(top: 2, right: 2, bottom: 3, left: 1, owner: 1)
        ],
        [Stone(top: 2, right: 3, bottom: 2, left: 2, owner: 1),
         Stone(top: 3, right: 3, bottom: 1, left: 2, owner: 1),
         Stone(top: 3, right: 1, bottom: 3, left: 2, owner: 1),
         Stone(top: 2, right: 3, bottom: 2, left: 3, owner: 1),
         Stone(top: 1, right: 2, bottom: 3, left: 1, owner: 1)
        ],
        [Stone(top: 3, right: 2, bottom: 3, left: 1, owner: 1),
         Stone(top: 2, right: 3, bottom: 3, left: 2, owner: 1),
         Stone(top: 4, right: 3, bottom: 2, left: 2, owner: 1),
         Stone(top: 1, right: 2, bottom: 3, left: 2, owner: 1),
         Stone(top: 2, right: 1, bottom: 4, left: 2, owner: 1)
        ],
        [Stone(top: 3, right: 3, bottom: 3, left: 2, owner: 1),
         Stone(top: 1, right: 3, bottom: 4, left: 1, owner: 1),
         Stone(top: 2, right: 2, bottom: 3, left: 3, owner: 1),
         Stone(top: 3, right: 3, bottom: 3, left: 3, owner: 1),
         Stone(top: 2, right: 4, bottom: 4, left: 3, owner: 1)
        ],
        [Stone(top: 3, right: 3, bottom: 4, left: 3, owner: 1),
         Stone(top: 4, right: 4, bottom: 4, left: 3, owner: 1),
         Stone(top: 3, right: 3, bottom: 3, left: 3, owner: 1),
         Stone(top: 4, right: 3, bottom: 4, left: 3, owner: 1),
         Stone(top: 3, right: 4, bottom: 3, left: 3, owner: 1)
        ]
    ]
}
