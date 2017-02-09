//
//  GamesViewController.swift
//  queRule
//
//  Created by Juan Manuel Jimenez Sanchez on 8/02/17.
//  Copyright © 2017 Juan Manuel Jimenez Sanchez. All rights reserved.
//

import UIKit
import CoreData

class GamesViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var filterControl: UISegmentedControl!
    
    var managedObjectContext: NSManagedObjectContext? = nil
    var lstGames: [Game] = [Game]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    /**
     Al string pasado por parametro le damos color negro hasta los (:) y al resto le aplicamos el color pasado por parametro
     
     - parameters:
        - string: la cadena a la que le queremos aplicar el formato
        - color: el color que queremos aplicar despues de los (:)
     
     - returns:
    la cadena ya formateada
     */
    func formatColors(string: String, color: UIColor) -> NSMutableAttributedString {
        let length = string.characters.count
        let colonPosition = string.indexOf(target: ":")!
        
        let myMutableString = NSMutableAttributedString(string: string, attributes: nil)
        
        myMutableString.addAttribute(NSForegroundColorAttributeName, value: color, range: NSRange(location: 0, length: length))
        myMutableString.addAttribute(NSForegroundColorAttributeName, value: UIColor.black, range: NSRange(location: 0, length: colonPosition + 1))
        
        return myMutableString
    }
}

extension String {
    /**
     - parameters:
        - target: la cadena que queremos buscar
     
     - returns:
     la posición en el string del primer caracter de la cadena pasada por parametro
     */
    func indexOf(target: String) -> Int? {
        if let range = self.range(of: target) {
            return distance(from: self.startIndex, to: range.lowerBound)
        }
        return nil
    }
}
