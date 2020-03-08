//: A UIKit based Playground for presenting user interface
  
import UIKit
import PlaygroundSupport

struct Grid<T> {
    let columns: Int
    let rows: Int
    private var array: Array<T?>
    
    init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
        array = Array<T?>(repeating: nil, count: rows*columns)
    }
    
    subscript(column: Int, row: Int) -> T? {
        get {
            return array[row*columns + column]
        }
        set {
            array[row*columns + column] = newValue
        }
    }
}

class Tile: Equatable {
    
    var x: Int
    var y: Int
    var isRevealed = false
    var isBomb = false
    var numberOfNeighbours = 0
    var button: UIButton
    
    init(with button: UIButton, x:Int, y: Int) {
        self.x = x
        self.y = y
        self.button = button
    }
    
    func show() {
        
        if isRevealed {
            if isBomb {
                UIView.animate(withDuration: 0.3) {
                    self.button.backgroundColor = .red
                    self.button.setTitle("💣", for: .normal)
                }
            } else {
                if numberOfNeighbours > 0 {
                    UIView.animate(withDuration: 0.3) {
                        self.button.backgroundColor = UIColor.init(white: 0.3, alpha: 0.9)
                        self.button.setTitle("\(self.numberOfNeighbours)", for: .normal)
                    }
                }
            }
        }
    }
    
    func reveal(grid: Grid<Tile>) {
        isRevealed = true
        show()
        if numberOfNeighbours == 0 {
            // flood fill time!gri
            floodfill(for: grid)
        }

    }
    
    func floodfill(for grid: Grid<Tile>) {
        for xOffset in -1...1 {
            let i = self.x + xOffset
            if i < 0 || i >= 8 { continue }
            
            for yOffset in -1...1 {
                let j = self.y + yOffset
                if j < 0 || j >= 8 { continue }

                guard let neighbour = grid[j, i] else {return}
                if !neighbour.isRevealed {
                    neighbour.reveal(grid: grid)
                    UIView.animate(withDuration: 0.3) {
                        neighbour.button.backgroundColor = UIColor.init(white: 0.3, alpha: 0.7)
                    }

                }
            }
        }
    }
    
    static func == (lhs: Tile, rhs: Tile) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }

}

class MyViewController : UIViewController {
    let columns = 8
    let rows = 8
    
    let screenWidth = 400
    let screenHeight = 800
    let totalBombs = 10
    
    lazy var squareSize = {
        Int(self.screenWidth) / self.columns
    }()
    
    lazy var xPadding = {
        (Int(self.screenWidth) - self.squareSize * self.columns ) / 2
    }()
    
    lazy var yPadding = {
        (Int(self.screenHeight) - self.squareSize * self.rows ) / 2
    }()
    
    var grid: Grid<Tile>
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        grid = Grid(columns: columns, rows: rows)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init with coder not implemented")
    }
    
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white
        self.view = view
        
        addTitle(title: "MINESWEEPER")
        generateGrid()
    }
    
    func addTitle(title: String) {
        let label = UILabel()
        label.frame = CGRect(x: 400 / 2 - 100, y: 50, width: 200, height: 20)
        label.text = title
        label.textColor = .black
        label.textAlignment = .center
        view.addSubview(label)
    }
    
    func generateGrid() {
        for i in 0..<rows {
            for j in 0..<columns {
                let xOffet = j * Int(squareSize) + xPadding
                let yOffest = i * Int(squareSize) + yPadding
                let tag = (i*rows) + j
                let square = createButton(with: CGSize(width: squareSize, height: squareSize),
                                          origin: CGPoint(x: xOffet, y: yOffest),
                                          tag: tag)
                
                grid[j, i] = Tile(with: square, x: i, y:j)
                view.addSubview(square)
            }
        }
        
        for _ in 0..<totalBombs {
            let randomRow = Int(arc4random_uniform(UInt32(rows)))
            let randomCols = Int(arc4random_uniform(UInt32(columns)))
            
            if let tile = grid[randomCols, randomRow] {
                tile.isBomb = true
            }
        }
        
        for i in 0..<rows {
            for j in 0..<columns {
                guard let tile = grid[j, i] else {return}
                countNeighbours(for: tile)
            }
        }
    }
    
    func countNeighbours(for tile: Tile) {

        if tile.isBomb {
            tile.numberOfNeighbours = -1
            return
        }
        
        var total = 0
        for xOffset in -1...1 {
            let i = tile.x + xOffset
            if i < 0 || i >= rows { continue }
            
            for yOffset in -1...1 {
                let j = tile.y + yOffset
                if j < 0 || j >= columns { continue }

                guard let neighbour = grid[j, i] else {return}
                if neighbour.isBomb {
                    total += 1
                }
            }
        }
        tile.numberOfNeighbours = total
    }
    

    func createButton(with size:CGSize, origin: CGPoint, tag: Int) -> UIButton {
        let button = UIButton(frame: CGRect(origin: origin, size: size))
        button.addTarget(self, action: #selector(buttonPressed(sender:)), for: .touchDown)
        button.backgroundColor = .lightGray
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.tintColor = .orange
        button.tag = tag
        return button
    }
    
    @objc func buttonPressed(sender: UIButton) {
        let j = (Int(sender.frame.origin.x) - xPadding) / squareSize
        let i = (Int(sender.frame.origin.y) - yPadding) / squareSize

        guard let tile = grid[j, i] else {return}
        tile.reveal(grid: grid)
    }
}
    
// Present the view controller in the Live View window
let viewController = MyViewController()
viewController.preferredContentSize = CGSize(width: viewController.screenWidth, height: viewController.screenHeight)
PlaygroundPage.current.liveView = viewController
