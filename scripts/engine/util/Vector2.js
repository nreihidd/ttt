//=========================================================
// Vector2

function Vector2(x, y) {
    this.x = x;
    this.y = y;
}

Vector2.prototype.clone = function() {
    return new Vector2(this.x, this.y);
}

Vector2.prototype.add = function(v) {
    this.x += v.x;
    this.y += v.y;
}
Vector2.prototype.subtract = function(v) {
    this.x -= v.x;
    this.y -= v.y;
}
Vector2.prototype.scale = function(s) {
    this.x *= s;
    this.y *= s;
}
Vector2.prototype.normalize = function(v) {
    var length = this.length();
    this.x /= length;
    this.y /= length;
}

Vector2.prototype.length = function() {
    return Math.sqrt(this.x * this.x + this.y * this.y);
}
Vector2.prototype.dot = function(v) {
    return this.x * v.x + this.y * v.y;
}
Vector2.prototype.cross = function(v) {
    return this.x * v.y - this.y * v.x;
}