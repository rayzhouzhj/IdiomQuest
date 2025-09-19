//
//  temp.swift
//  Idiom Quest
//
//  Created by Ray Zhou on 11/9/2025.
//
import Foundation
import CoreData

struct Idiom: Codable {
    let word: String
    let pinyin: String
    let explanation: String
    let example: String?
    let derivation: String?
    let abbreviation: String?
    
    enum CodingKeys: String, CodingKey {
        case word
        case pinyin
        case explanation
        case example
        case derivation
        case abbreviation
    }
}

class CoreDataStack {
    let persistentContainer: NSPersistentContainer
    
    init(modelName: String, storeURL: URL, modelURL: URL?) {
        guard let modelURL = modelURL ?? Bundle.main.url(forResource: modelName, withExtension: "momd") else {
            fatalError("Failed to find data model: \(modelName)")
        }
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to load data model: \(modelName)")
        }
        
        let container = NSPersistentContainer(name: modelName, managedObjectModel: managedObjectModel)
        let description = NSPersistentStoreDescription(url: storeURL)
        description.type = NSSQLiteStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Failed to load Core Data store: \(error), \(error.userInfo)")
            }
        }
        self.persistentContainer = container
    }
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("Core Data context saved successfully")
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

func convertJSONToCoreData(jsonFilePath: String, modelName: String, outputSQLitePath: String, modelURL: URL? = nil) {
    guard FileManager.default.fileExists(atPath: jsonFilePath) else {
        fatalError("JSON file not found at: \(jsonFilePath)")
    }
    
    do {
        let jsonURL = URL(fileURLWithPath: jsonFilePath)
        let jsonData = try Data(contentsOf: jsonURL)
        let idioms = try JSONDecoder().decode([Idiom].self, from: jsonData)
        print("Parsed \(idioms.count) idioms from JSON")
        
        let outputURL = URL(fileURLWithPath: outputSQLitePath)
        let stack = CoreDataStack(modelName: modelName, storeURL: outputURL, modelURL: modelURL)
        let context = stack.context
        
        guard context.persistentStoreCoordinator?.managedObjectModel.entitiesByName["Chengyu"] != nil else {
            fatalError("Chengyu entity not found in data model. Check .xcdatamodeld file.")
        }
        
        context.performAndWait {
            for (index, idiom) in idioms.enumerated() {
                guard let entity = NSEntityDescription.insertNewObject(forEntityName: "Chengyu", into: context) as? NSManagedObject else {
                    fatalError("Failed to create Chengyu entity")
                }
                entity.setValue(idiom.word, forKey: "word")
                entity.setValue(idiom.pinyin, forKey: "pinyin")
                entity.setValue(idiom.explanation, forKey: "explanation")
                entity.setValue(idiom.example, forKey: "example")
                entity.setValue(idiom.derivation, forKey: "derivation")
                entity.setValue(idiom.abbreviation, forKey: "abbreviation")
                // Remove isLearned if not in Chengyu entity
                
                if index % 1000 == 0 {
                    print("Inserted \(index) idioms...")
                }
            }
            
            stack.saveContext()
            print("Successfully converted \(idioms.count) idioms to SQLite at: \(outputSQLitePath)")
        }
    } catch {
        fatalError("Error processing JSON: \(error)")
    }
}

func testDatabase() {
    let context = CoreDataManager.shared.context
    
    // Fetch a Chengyu
    let chengyuRequest = NSFetchRequest<NSManagedObject>(entityName: "Chengyu")
    chengyuRequest.fetchLimit = 1
    do {
        let idiom = try context.fetch(chengyuRequest).first
        let word = idiom?.value(forKey: "word") as? String ?? "None"
        print("Test idiom: \(word)")
        
//        // Check or create UserData
//        let userDataRequest = NSFetchRequest<NSManagedObject>(entityName: "UserData")
//        userDataRequest.predicate = NSPredicate(format: "word == %@", word)
//        if let userData = try context.fetch(userDataRequest).first {
//            print("UserData isLearned: \(userData.value(forKey: "isLearned") ?? false)")
//        } else {
//            let userData = NSEntityDescription.insertNewObject(forEntityName: "UserData", into: context)
//            userData.setValue(word, forKey: "word")
//            userData.setValue(true, forKey: "isLearned")
//            try context.save()
//            print("Created UserData for \(word)")
//        }
    } catch {
        print("Fetch error: \(error)")
    }
}

//@main
struct ConvertIdioms {
    static func main() {
        let jsonFilePath = "/Users/rayzhou/Downloads/idiom.json" // Update with your JSON file path
        let modelName = "Idiom_Quest" // Match .xcdatamodeld name
        let outputSQLitePath = "/Users/rayzhou/Downloads/ChengyuData.sqlite" // Update with desired output path
        let modelURL: URL? = nil // Set to .momd path if running standalone
        
        convertJSONToCoreData(jsonFilePath: jsonFilePath, modelName: modelName, outputSQLitePath: outputSQLitePath, modelURL: modelURL)
        
        testDatabase()
    }
}
