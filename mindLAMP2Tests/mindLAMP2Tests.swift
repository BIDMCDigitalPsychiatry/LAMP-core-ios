// mindLAMP2Tests

import XCTest
import mindLAMP_2

final class mindLAMP2Tests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCurrentStreak() throws {
        let sut = StreakWidgetHelper()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let dates = [
            dateFormatter.date(from: "2024-05-01 10:00:00")!,
            dateFormatter.date(from: "2024-05-01 15:00:00")!,
            dateFormatter.date(from: "2024-05-02 12:00:00")!,
            dateFormatter.date(from: "2024-05-02 18:00:00")!,
            dateFormatter.date(from: "2024-05-03 08:00:00")!,
            
            dateFormatter.date(from: "2023-05-05 09:00:00")!,
            dateFormatter.date(from: "2023-05-06 10:00:00")!,
            dateFormatter.date(from: "2023-05-07 11:00:00")!,
            dateFormatter.date(from: "2023-05-08 12:00:00")!,
            
            dateFormatter.date(from: "2024-05-08 12:00:00")!,
            dateFormatter.date(from: "2024-06-02 12:00:00")!,
            dateFormatter.date(from: "2024-06-03 12:00:00")!
            
        ]
        let currentStreak = sut.findCurrentStreak(from: dates)
        
        XCTAssertEqual(currentStreak, 2)
    }

    func testCurrentAndLongest() throws {
        
        let sut = StreakWidgetHelper()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let dates = [
            dateFormatter.date(from: "2024-05-01 10:00:00")!,
            dateFormatter.date(from: "2024-05-01 15:00:00")!,
            dateFormatter.date(from: "2024-05-02 12:00:00")!,
            dateFormatter.date(from: "2024-05-02 18:00:00")!,
            dateFormatter.date(from: "2024-05-03 08:00:00")!,
            
            dateFormatter.date(from: "2023-05-05 09:00:00")!,
            dateFormatter.date(from: "2023-05-06 10:00:00")!,
            dateFormatter.date(from: "2023-05-07 11:00:00")!,
            dateFormatter.date(from: "2023-05-08 12:00:00")!,
            
            dateFormatter.date(from: "2024-05-08 12:00:00")!,
            dateFormatter.date(from: "2024-06-02 12:00:00")!,
            dateFormatter.date(from: "2024-06-03 12:00:00")!
            
        ]

        let streak:(current: Int, max: Int) = sut.findCurentAndLongestStreak(dates: dates)
        
        XCTAssertEqual(streak.max, 4)
        XCTAssertEqual(streak.current, 2)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
