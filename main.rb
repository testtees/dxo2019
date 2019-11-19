require 'dxopal'
include DXOpal

GROUND_Y = 400
Image.register(:player, 'images/player.png')
Image.register(:apple, 'images/apple.png')
Image.register(:bomb, 'images/bomb.png')

# 読み込みたい音声を登録する
Sound.register(:get, 'sounds/get.wav')
Sound.register(:explosion, 'sounds/explosion.wav')

# ゲームの状態を記憶するハッシュを追加
GAME_INFO = {
  scene: :title,  # 現在のシーン(起動直後は:title)
  score: 0      # 現在のスコア
}

#アイテムクラス
class Item < Sprite
  def initialize(image)
    x = rand(Window.width - image.width)  # x座標をランダムに決める
    y = 0
    super(x, y, image)
    @speed_y = rand(7) + 4  # 落ちる速さをランダムに決める
  end

  def update
    self.y += @speed_y
    if self.y > Window.height
      self.vanish
    end
  end
end

# 加点アイテムのクラスを追加
class Apple < Item
  def initialize
    super(Image[:apple])
    # 衝突範囲を円で設定(中心x, 中心y, 半径)
    self.collision = [image.width / 2, image.height / 2, 56]
  end

  # playerと衝突したとき呼ばれるメソッドを追加
  def hit
    # 効果音を鳴らす
    Sound[:get].play
    self.vanish
    GAME_INFO[:score] += 10
  end
end

# 妨害アイテムのクラスを追加
class Bomb < Item
  def initialize
    super(Image[:bomb])
    # 衝突範囲を円で設定(中心x, 中心y, 半径)
    self.collision = [image.width / 2, image.height / 2, 42]
  end

  # playerと衝突したとき呼ばれるメソッドを追加
  def hit
    # 効果音を鳴らす
    Sound[:explosion].play
    self.vanish
    # スコアを0にするのをやめて、ゲームオーバー画面に遷移するようにした
    GAME_INFO[:scene] = :game_over
  end
end

# アイテム群を管理するクラスを追加
class Items
  # 同時に出現するアイテムの個数
  N = 5

  def initialize
    @items = []
  end

  def update(player)
    @items.each{|x| x.update(player)}
    # playerとitemsが衝突しているかチェックする。衝突していたらhitメソッドが呼ばれる
    Sprite.check(player, @items)
    Sprite.clean(@items)

    # 消えた分を補充する(常にアイテムがN個あるようにする)
    (N - @items.size).times do
      #@items.push(Item.new)
      # どっちのアイテムにするか、ランダムで決める
      if rand(1..100) < 40
        @items.push(Apple.new)
      else
        @items.push(Bomb.new)
      end
    end
  end

  def draw
    # 各スプライトのdrawメソッドを呼ぶ
    Sprite.draw(@items)
  end
end

# プレイヤーを表すクラスを定義
class Player < Sprite
  def initialize
    x = Window.width / 2
    y = GROUND_Y - Image[:player].height
    image = Image[:player]
    super(x, y, image)
    # 当たり判定を円で設定(中心x, 中心y, 半径)
    self.collision = [image.width / 2, image.height / 2, 16]
  end

  # 移動処理(xからself.xになった)
  def update
    if Input.key_down?(K_LEFT) && self.x > 0
      self.x -= 8
    elsif Input.key_down?(K_RIGHT) && self.x < (Window.width - Image[:player].width)
      self.x += 8
    end
  end
end


Window.load_resources do
  player = Player.new
  items = Items.new

  Window.loop do
    #背景描画
    Window.draw_box_fill(0, 0, Window.width, GROUND_Y, [32, 64, 160])
    Window.draw_box_fill(0, GROUND_Y, Window.width, Window.height, [0, 128, 0])
    Window.draw_font(0, 0, "SCORE: #{GAME_INFO[:score]}", Font.default)

    # シーンごとの処理
    case GAME_INFO[:scene]
    when :title
      # タイトル画面
      Window.draw_font(0, 30, "PRESS SPACE", Font.default)
      # スペースキーが押されたらシーンを変える
      if Input.key_push?(K_SPACE)
        GAME_INFO[:scene] = :playing
      end
    when :playing
      # ゲーム中
      player.update
      items.update(player)

      player.draw
      items.draw
    when :game_over
      # ゲームオーバー画面
      Window.draw_font(0, 30, "PRESS SPACE", Font.default)
      player.draw
      items.draw
      # スペースキーが押されたらゲームの状態をリセットし、シーンを変える
      if Input.key_push?(K_SPACE)
        player = Player.new
        items = Items.new
        GAME_INFO[:score] = 0
        GAME_INFO[:scene] = :playing
      end
    end
  end
end
