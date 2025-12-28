var selectedHits: [MinimapHit] {
        var _selectedHits = [MinimapHit]()
        for bin in bins {
            _selectedHits.append(contentsOf: bin.hits(numberToRetrieve: hitsPerBin))
        }
        return _selectedHits
    }