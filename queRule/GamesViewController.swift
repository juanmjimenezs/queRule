//
//  GamesViewController.swift
//  queRule
//
//  Created by Juan Manuel Jimenez Sanchez on 8/02/17.
//  Copyright © 2017 Juan Manuel Jimenez Sanchez. All rights reserved.
//

import UIKit
import CoreData

class GamesViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var filterControl: UISegmentedControl!
    
    var managedObjectContext: NSManagedObjectContext? = nil
    var lstGames: [Game] = [Game]()

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.delegate = self
        collectionView.dataSource = self
        
        //Permite que aunque no tengamos la pantalla llena de celdas aún así podamos tener el efecto de tirar para abajo
        collectionView.alwaysBounceVertical = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.performGamesQuery()
    }

    @IBAction func filterChanged(_ sender: UISegmentedControl) {
        self.performGamesQuery()
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
    
    ///Realiza la consulta de los juegos, llena el array de juegos y recarga la collection view
    func performGamesQuery() {
        let request: NSFetchRequest<Game> = Game.fetchRequest()
        let sortByDate = NSSortDescriptor(key: "dateCreated", ascending: false)
        
        request.sortDescriptors = [sortByDate]
        
        if self.filterControl.selectedSegmentIndex == 0 {
            let predicate = NSPredicate(format: "borrowed = true")
            request.predicate = predicate
        }
        
        do {
            let fetchedGames = try self.managedObjectContext?.fetch(request)
            if let fetchedGames = fetchedGames {
                self.lstGames = fetchedGames
                collectionView.reloadData()
            }
        } catch {
            print("Error recuperando datos de core data")
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        
        if offsetY < -120 {
            performSegue(withIdentifier: "addGameSegue", sender: self)
        }
    }
}

extension GamesViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //Si no hay elementos entonces colocamos una imagen de fondo...
        if self.lstGames.count == 0 {
            let imageView = UIImageView(image: #imageLiteral(resourceName: "img_empty_screen"))
            imageView.contentMode = .center
            collectionView.backgroundView = imageView
        } else {
            collectionView.backgroundView = UIView()
        }
        
        return lstGames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GameCell", for: indexPath) as! GameCell
        
        let game = self.lstGames[indexPath.row]
        
        cell.lblTitle.text = game.title
        
        var highlightColor = #colorLiteral(red: 0.9058823529, green: 0.2980392157, blue: 0.2352941176, alpha: 1)
        if !game.borrowed {
            highlightColor = #colorLiteral(red: 0.2039215686, green: 0.5960784314, blue: 0.8588235294, alpha: 1)
        }
        
        cell.lblBorrowed.attributedText = self.formatColors(string: "PRESTADO: \(game.borrowed ? "SI" : "NO")", color: highlightColor)
        
        if let borrowedTo = game.borrowedTo {
            cell.lblBorrowedTo.attributedText = self.formatColors(string: "A: \(borrowedTo)", color: highlightColor)
        } else {
            cell.lblBorrowedTo.attributedText = self.formatColors(string: "A: --", color: highlightColor)
        }

        if let borrowedDate = game.borrowedDate as? Date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy"
            cell.lblBorrowedDate.attributedText = self.formatColors(string: "FECHA: \(dateFormatter.string(from: borrowedDate))", color: highlightColor)
        } else {
            cell.lblBorrowedDate.attributedText = self.formatColors(string: "FECHA: --", color: highlightColor)
        }
        
        if let image = game.image as? Data {
            cell.imageView.image = UIImage(data: image)
        }
        
        cell.layer.masksToBounds = false
        cell.layer.shadowOffset = CGSize(width: 1, height: 1)
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowRadius = 2.0
        cell.layer.shadowOpacity = 0.2
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.size.width - 20, height: 120.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "editGameSegue", sender: self)
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
