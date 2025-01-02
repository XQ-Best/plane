//
//  ContentView.swift
//  plane
//
//  Created by 徐铨 on 2024/12/25.
//

import SwiftUI

// 子弹结构体
struct Bullet: Identifiable {
    let id = UUID()
    var position: CGPoint
    let damage: CGFloat = 10
    var velocity: CGFloat = 15  // 增加子弹速度
    var direction: CGFloat  // 子弹运动方向（弧度）
    var bounceCount = 0     // 反弹次数
}

// 敌人结构体
struct Enemy: Identifiable {
    let id = UUID()
    var position: CGPoint
    var emoji: String
    var health: CGFloat = 100
    var velocity: CGFloat
    var hasCollided: Bool = false
}

// 爱心结构体
struct Heart: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGFloat
}

struct ContentView: View {
    // 游戏状态枚举
    private enum GameState {
        case welcome    // 欢迎界面
        case playing    // 游戏进行中
        case gameOver   // 游戏结束
    }
    
    // 状态变量
    @State private var playerPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 100)
    @State private var playerHealth: CGFloat = 300
    @State private var bullets: [Bullet] = []
    @State private var enemies: [Enemy] = []
    @State private var hearts: [Heart] = []
    @State private var score = 0
    @State private var shootingInterval: TimeInterval = 0.05  // 进一步减小射击间隔
    @State private var lastShotTime: TimeInterval = Date().timeIntervalSinceReferenceDate
    @State private var isGameActive = true
    @State private var isGameOver = false
    @State private var showExplosion = false
    @State private var explosionScale: CGFloat = 1.0
    @State private var gameState: GameState = .welcome
    @State private var playerLevel = 1
    @State private var levelTimer: TimeInterval = 0
    @State private var lastUpdateTime: TimeInterval = Date().timeIntervalSinceReferenceDate
    @State private var isShooting = false  // 新增：是否正在射击
    @State private var shootingTimer: Timer?  // 新增：射击定时器
    @State private var enemySpeedScore: Int = 0  // 用于计算敌人速度的分数
    @State private var gameTimer: Timer?  // 新增：游戏主循环定时器
    
    let emojis = ["👾", "👻", "🤖", "👽", "🎃"]
    
    private let MAX_HEALTH: CGFloat = 500  // 最大血量
    private let INITIAL_HEALTH: CGFloat = 300  // 初始血量
    private let INITIAL_SHOOTING_INTERVAL: TimeInterval = 0.1  // 初始射击间隔
    private let INITIAL_ENEMY_VELOCITY: CGFloat = 3.0  // 初始敌人速度
    private let INITIAL_HEART_VELOCITY: CGFloat = 3.0  // 初始爱心速度
    private let INITIAL_BULLET_VELOCITY: CGFloat = 15.0  // 初始子弹速度
    
    // 添加屏幕适配相关的计算属性
    private var screenSize: CGSize {
        let bounds = UIScreen.main.bounds
        return CGSize(width: bounds.width, height: bounds.height)
    }
    
    // 添加适配比例计算
    private var adaptiveScale: CGFloat {
        let baseWidth: CGFloat = 375.0  // 基准宽度（iPhone 8）
        return screenSize.width / baseWidth
    }
    
    var body: some View {
        ZStack {
            // 背景
            Color.black.edgesIgnoringSafeArea(.all)
            
            switch gameState {
            case .welcome:
                // 欢迎界面
                VStack {
                    Spacer()
                    
                    Text("飞机大战")
                        .font(.system(size: 50 * adaptiveScale, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 20 * adaptiveScale)
                        .shadow(color: .blue, radius: 10, x: 0, y: 0)
                    
                    Text("🛩️")
                        .font(.system(size: 80 * adaptiveScale))
                        .padding()
                    
                    Button(action: {
                        withAnimation {
                            startGame()
                        }
                    }) {
                        Text("开始游戏")
                            .font(.system(size: 24 * adaptiveScale, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 40 * adaptiveScale)
                            .padding(.vertical, 15 * adaptiveScale)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.blue)
                                    .shadow(color: .blue, radius: 5)
                            )
                    }
                    
                    Spacer()
                    
                    Text("联系方式: xuquan8852@hotmail.com")
                        .font(.system(size: 16 * adaptiveScale))
                        .foregroundColor(.gray)
                        .padding(.bottom, 20 * adaptiveScale)
                }
                .transition(.scale.combined(with: .opacity))
                
            case .playing:
                // 游戏界面
                VStack {
                    HStack {
                        Text("分数: \(score)")
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    Spacer()
                    
                    // 底部状态栏
                    HStack {
                        // 左侧血量显示
                        HStack(spacing: 5) {
                            ForEach(0..<Int(playerHealth/100), id: \.self) { _ in
                                Text("❤️")
                                    .font(.system(size: 24))
                            }
                        }
                        .padding(.leading)
                        .padding(.bottom)
                        
                        Spacer()
                        
                        // 右侧等级显示
                        Text("Lv.\(playerLevel)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.yellow)
                            .padding(.trailing)
                            .padding(.bottom)
                    }
                }
                
                // 子弹
                ForEach(bullets) { bullet in
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 8, height: 8)
                        .position(bullet.position)
                }
                
                // 敌人
                ForEach(enemies) { enemy in
                    Text(enemy.emoji)
                        .font(.system(size: 40))
                        .position(enemy.position)
                }
                
                // 爱心
                ForEach(hearts) { heart in
                    Text("❤️")
                        .font(.system(size: 30))
                        .position(heart.position)
                }
                
                // 玩家飞机
                if showExplosion {
                    Text("💥")
                        .font(.system(size: 60))
                        .position(playerPosition)
                        .scaleEffect(explosionScale)
                } else {
                    Text("🛩️")
                        .font(.system(size: 50))
                        .position(playerPosition)
                }
                
            case .gameOver:
                // 游戏结束画面
                VStack {
                    Text("💥 GAME OVER 💥")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.red)
                        .padding()
                        .shadow(color: .red, radius: 10, x: 0, y: 0)
                    
                    Text("最终得分: \(score)")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .shadow(color: .white, radius: 5, x: 0, y: 0)
                    
                    Button(action: {
                        withAnimation {
                            completeReset()
                        }
                    }) {
                        Text("再来一局")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.blue)
                                    .shadow(color: .blue, radius: 5)
                            )
                    }
                    .padding(.top, 30)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: screenSize.width, height: screenSize.height)
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    if gameState == .playing {
                        playerPosition = value.location
                    }
                }
        )
    }
    
    // 游戏循环
    private func startGameLoop() {
        // 创建新的游戏主循环
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            if isGameActive {
                updateGame()
            }
        }
        
        // 启动射击系统
        startShooting()
    }
    
    // 新增：开始射击函数
    private func startShooting() {
        isShooting = true
        shootingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if isGameActive && isShooting {
                fireBullets()
            }
        }
    }
    
    // 游戏更新
    private func updateGame() {
        updateBulletPositions()
    }
    
    // 抽取子弹发射逻辑
    private func fireBullets() {
        var newBullets: [Bullet] = []
        let bulletStartY = playerPosition.y - 30 * adaptiveScale
        
        switch playerLevel {
        case 1:
            newBullets.append(createBullet(at: playerPosition.x, y: bulletStartY, direction: -.pi/2))
        case 2:
            newBullets.append(createBullet(at: playerPosition.x, y: bulletStartY, direction: -.pi/2 - 0.2))
            newBullets.append(createBullet(at: playerPosition.x, y: bulletStartY, direction: -.pi/2 + 0.2))
        case 3:
            newBullets.append(createBullet(at: playerPosition.x, y: bulletStartY, direction: -.pi/2))
            newBullets.append(createBullet(at: playerPosition.x, y: bulletStartY, direction: -.pi/2 - 0.3))
            newBullets.append(createBullet(at: playerPosition.x, y: bulletStartY, direction: -.pi/2 + 0.3))
        default:
            break
        }
        
        bullets.append(contentsOf: newBullets)
    }
    
    private func createBullet(at x: CGFloat, y: CGFloat, direction: CGFloat) -> Bullet {
        Bullet(
            position: CGPoint(x: x, y: y),
            velocity: INITIAL_BULLET_VELOCITY * adaptiveScale,
            direction: direction
        )
    }
    
    private func isValidEnemyPosition(_ position: CGPoint, excluding: Enemy? = nil) -> Bool {
        for enemy in enemies {
            if let excludingEnemy = excluding, excludingEnemy.id == enemy.id {
                continue
            }
            if abs(position.x - enemy.position.x) < 50 {
                return false
            }
        }
        return true
    }
    
    private func gameOver() {
        // 停止所有游戏系统
        isGameActive = false
        isShooting = false
        
        // 停止所有定时器
        gameTimer?.invalidate()
        gameTimer = nil
        shootingTimer?.invalidate()
        shootingTimer = nil
        
        // 显示爆炸效果
        withAnimation(.easeIn(duration: 0.3)) {
            showExplosion = true
            explosionScale = 2.0
        }
        
        // 延迟显示游戏结束画面
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showExplosion = false
                gameState = .gameOver
                enemies.removeAll()
                bullets.removeAll()
            }
        }
    }
    
    private func startGame() {
        // 先停止所有现有定时器
        gameTimer?.invalidate()
        gameTimer = nil
        shootingTimer?.invalidate()
        shootingTimer = nil
        
        // 重置所有游戏状态到初始值
        isGameActive = true
        isShooting = false
        playerHealth = INITIAL_HEALTH
        score = 0
        enemySpeedScore = 0
        levelTimer = 0
        playerLevel = 1
        shootingInterval = INITIAL_SHOOTING_INTERVAL
        showExplosion = false
        explosionScale = 1.0
        isGameOver = false
        
        // 清空所有游戏对象
        bullets.removeAll()
        enemies.removeAll()
        hearts.removeAll()
        
        // 重置玩家位置
        playerPosition = CGPoint(x: screenSize.width / 2, y: screenSize.height - 100)
        
        // 重置时间相关变量
        lastUpdateTime = Date().timeIntervalSinceReferenceDate
        lastShotTime = Date().timeIntervalSinceReferenceDate
        
        // 设置游戏状态
        gameState = .playing
        
        // 启动新的游戏循环
        startGameLoop()
    }
    
    private func resetGame() {
        withAnimation {
            // 停止所有计时器和游戏状态
            isGameActive = false
            shootingTimer?.invalidate()
            shootingTimer = nil
            isShooting = false
            
            // 重置显示效果
            showExplosion = false
            explosionScale = 1.0
            isGameOver = false
            
            // 清空所有游戏对象
            bullets.removeAll()
            enemies.removeAll()
            hearts.removeAll()
        }
    }
    
    // 添加子弹位置更新函数
    private func updateBulletPositions() {
        // 更新子弹
        for (index, bullet) in bullets.enumerated() where index < bullets.count {
            var updatedBullet = bullet
            
            let dx = cos(bullet.direction) * bullet.velocity
            let dy = sin(bullet.direction) * bullet.velocity
            updatedBullet.position.x += dx
            updatedBullet.position.y += dy
            
            // 如果子弹超出顶部或底部，移除子弹
            if updatedBullet.position.y < 0 || updatedBullet.position.y > screenSize.height {
                bullets.remove(at: index)
                continue
            }
            
            // 只处理左右两侧的反弹
            if updatedBullet.bounceCount < 2 {
                if updatedBullet.position.x <= 0 || updatedBullet.position.x >= screenSize.width {
                    updatedBullet.direction = .pi - updatedBullet.direction
                    updatedBullet.bounceCount += 1
                }
            }
            
            bullets[index] = updatedBullet
        }
        
        // 移除超出边界或反弹次数过多的子弹
        bullets.removeAll { bullet in
            bullet.bounceCount >= 2 ||
            bullet.position.x < -50 ||
            bullet.position.x > screenSize.width + 50
        }
        
        // 更新等级
        let currentTime = Date().timeIntervalSinceReferenceDate
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime  // 更新上次更新时间
        
        if gameState == .playing {
            levelTimer += deltaTime
            // 根据存活时间计算等级
            if levelTimer >= 30 && playerLevel == 1 {
                playerLevel = 2
            } else if levelTimer >= 60 && playerLevel == 2 {
                playerLevel = 3
            }
        }
        
        // 生成敌人
        if enemies.count < Int(Date().timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 10)) + 1 {
            let maxAttempts = 10
            var attempts = 0
            var position: CGPoint?
            
            while attempts < maxAttempts {
                let randomX = CGFloat.random(in: 25...screenSize.width-25)
                let testPosition = CGPoint(x: randomX, y: -50)
                if isValidEnemyPosition(testPosition) {
                    position = testPosition
                    break
                }
                attempts += 1
            }
            
            if let position = position {
                let baseVelocity = INITIAL_ENEMY_VELOCITY
                let speedIncrease = CGFloat(enemySpeedScore) * 0.02  // 更温和的速度增长
                let newEnemy = Enemy(
                    position: position,
                    emoji: emojis.randomElement() ?? "👾",
                    velocity: (baseVelocity + speedIncrease) * adaptiveScale
                )
                enemies.append(newEnemy)
            }
        }
        
        // 更新敌人位置
        for (index, enemy) in enemies.enumerated() {
            enemies[index].position.y += enemy.velocity
        }
        
        // 生成爱心（约1%的概率）
        if hearts.count < 1 && Double.random(in: 0...1) < 0.01 {
            let randomX = CGFloat.random(in: 25...screenSize.width-25)
            let heart = Heart(
                position: CGPoint(x: randomX, y: -50),
                velocity: INITIAL_HEART_VELOCITY * adaptiveScale
            )
            hearts.append(heart)
        }
        
        // 更新爱心位置
        for (index, heart) in hearts.enumerated() {
            hearts[index].position.y += heart.velocity
        }
        
        // 移除超出屏幕的爱心
        hearts.removeAll { $0.position.y > screenSize.height }
        
        // 检测爱心碰撞
        hearts.removeAll { heart in
            let collected = abs(heart.position.x - playerPosition.x) < 30 &&
                           abs(heart.position.y - playerPosition.y) < 30
            if collected {
                // 收集爱心时检查最血量
                playerHealth = min(playerHealth + 100, MAX_HEALTH)
            }
            return collected
        }
        
        // 碰撞检测
        enemies = enemies.map { enemy in
            var updatedEnemy = enemy
            
            // 检测与子弹的碰撞
            for (bulletIndex, bullet) in bullets.enumerated() {
                if abs(bullet.position.x - enemy.position.x) < 20 &&
                   abs(bullet.position.y - enemy.position.y) < 20 {
                    updatedEnemy.health -= bullet.damage
                    bullets.remove(at: bulletIndex)
                    break
                }
            }
            
            // 检测与玩家的碰撞
            if abs(enemy.position.x - playerPosition.x) < 40 &&
               abs(enemy.position.y - playerPosition.y) < 40 &&
               !updatedEnemy.hasCollided {
                playerHealth -= 100
                updatedEnemy.hasCollided = true
                if playerHealth <= 0 {
                    gameOver()
                }
            }
            
            return updatedEnemy
        }.filter { enemy in
            if enemy.health <= 0 || enemy.hasCollided {
                score += 1
                if score % 20 == 0 {  // 每20分增加一次速度
                    enemySpeedScore += 1
                }
                return false
            }
            return enemy.position.y < screenSize.height
        }
    }
    
    // 添加完全重置函数
    private func completeReset() {
        // 停止所有定时器
        gameTimer?.invalidate()
        gameTimer = nil
        shootingTimer?.invalidate()
        shootingTimer = nil
        
        // 清空所有游戏对象
        bullets.removeAll()
        enemies.removeAll()
        hearts.removeAll()
        
        // 切换到欢迎界面
        gameState = .welcome
    }
}

#Preview {
    ContentView()
}



