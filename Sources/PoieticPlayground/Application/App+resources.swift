//
//  App+resources.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 01/02/2026.
//

extension Application {
    func loadResources() {
        self.log("Loading textures...")
        textures["select"] = resourceLoader.loadTexture("icons/black/select.png")
        textures["place"] = resourceLoader.loadTexture("icons/black/place.png")
        textures["connect"] = resourceLoader.loadTexture("icons/black/connect.png")
        textures["pan"] = resourceLoader.loadTexture("icons/black/hand.png")
        self.log("\(textures.count) textures loaded")
    }
}
