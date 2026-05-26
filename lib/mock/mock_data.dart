import '../models/models.dart';

/// In-memory mock data used during development.
/// Replace with real API calls in production.
abstract final class MockData {
  // ── Categories ────────────────────────────────────────────────────────────
  static final List<Category> categories = [
    const Category(id: 'cat-1', name: 'Starters', icon: '🥗', itemCount: 8),
    const Category(id: 'cat-2', name: 'Mains', icon: '🍽️', itemCount: 14),
    const Category(id: 'cat-3', name: 'Grills', icon: '🥩', itemCount: 6),
    const Category(id: 'cat-4', name: 'Pasta', icon: '🍝', itemCount: 7),
    const Category(id: 'cat-5', name: 'Pizzas', icon: '🍕', itemCount: 10),
    const Category(id: 'cat-6', name: 'Desserts', icon: '🍮', itemCount: 5),
    const Category(id: 'cat-7', name: 'Beverages', icon: '🥤', itemCount: 12),
    const Category(id: 'cat-8', name: 'Sides', icon: '🍟', itemCount: 6),
  ];

  // ── Menu items ────────────────────────────────────────────────────────────
  static final List<MenuItem> menuItems = [
    // Starters
    const MenuItem(
      id: 'mi-101',
      name: 'Bruschetta al Pomodoro',
      categoryId: 'cat-1',
      price: 7.50,
      description: 'Toasted bread with fresh tomatoes, basil & garlic.',
      isVegetarian: true,
      preparationTimeMinutes: 8,
      tags: ['popular', 'vegetarian'],
    ),
    const MenuItem(
      id: 'mi-102',
      name: 'Soup of the Day',
      categoryId: 'cat-1',
      price: 6.00,
      description: 'Chef\'s daily soup served with crusty bread.',
      preparationTimeMinutes: 10,
    ),
    const MenuItem(
      id: 'mi-103',
      name: 'Prawn Cocktail',
      categoryId: 'cat-1',
      price: 11.00,
      description: 'Juicy prawns with Marie Rose sauce & lemon.',
      allergens: ['shellfish'],
      preparationTimeMinutes: 6,
      tags: ['popular'],
    ),
    const MenuItem(
      id: 'mi-104',
      name: 'Caprese Salad',
      categoryId: 'cat-1',
      price: 9.00,
      description: 'Fresh buffalo mozzarella, tomatoes & basil oil.',
      isVegetarian: true,
      isVegan: false,
      preparationTimeMinutes: 5,
    ),
    // Mains
    const MenuItem(
      id: 'mi-201',
      name: 'Grilled Salmon Fillet',
      categoryId: 'cat-2',
      price: 22.00,
      description: 'Atlantic salmon, asparagus, dill butter & new potatoes.',
      allergens: ['fish'],
      preparationTimeMinutes: 18,
      tags: ['healthy'],
    ),
    const MenuItem(
      id: 'mi-202',
      name: 'Chicken Tikka Masala',
      categoryId: 'cat-2',
      price: 16.50,
      description: 'Tender chicken in rich tomato-cream curry sauce & basmati.',
      preparationTimeMinutes: 20,
      tags: ['popular', 'spicy'],
    ),
    const MenuItem(
      id: 'mi-203',
      name: 'Mushroom Risotto',
      categoryId: 'cat-2',
      price: 14.00,
      description: 'Arborio rice, wild mushrooms, parmesan & truffle oil.',
      isVegetarian: true,
      allergens: ['dairy', 'gluten'],
      preparationTimeMinutes: 22,
    ),
    const MenuItem(
      id: 'mi-204',
      name: 'Fish & Chips',
      categoryId: 'cat-2',
      price: 15.00,
      description: 'Beer-battered cod, triple-cooked chips & mushy peas.',
      allergens: ['fish', 'gluten'],
      preparationTimeMinutes: 15,
      tags: ['popular'],
    ),
    // Grills
    const MenuItem(
      id: 'mi-301',
      name: '8oz Sirloin Steak',
      categoryId: 'cat-3',
      price: 28.00,
      description: 'Prime aged sirloin, grilled to order with peppercorn sauce.',
      preparationTimeMinutes: 20,
      tags: ['premium'],
    ),
    const MenuItem(
      id: 'mi-302',
      name: 'BBQ Ribs Half-Rack',
      categoryId: 'cat-3',
      price: 24.00,
      description: 'Slow-cooked pork ribs in smoky BBQ glaze with coleslaw.',
      preparationTimeMinutes: 25,
      tags: ['popular', 'premium'],
    ),
    // Pizzas
    const MenuItem(
      id: 'mi-501',
      name: 'Margherita',
      categoryId: 'cat-5',
      price: 12.00,
      description: 'San Marzano tomato, fresh mozzarella & basil.',
      isVegetarian: true,
      allergens: ['gluten', 'dairy'],
      preparationTimeMinutes: 14,
    ),
    const MenuItem(
      id: 'mi-502',
      name: 'Pepperoni Feast',
      categoryId: 'cat-5',
      price: 14.50,
      description: 'Double pepperoni, mozzarella & tomato base.',
      allergens: ['gluten', 'dairy'],
      preparationTimeMinutes: 14,
      tags: ['popular'],
    ),
    // Desserts
    const MenuItem(
      id: 'mi-601',
      name: 'Tiramisu',
      categoryId: 'cat-6',
      price: 7.50,
      description: 'Classic Italian tiramisu with espresso & mascarpone.',
      isVegetarian: true,
      allergens: ['dairy', 'eggs', 'gluten'],
      preparationTimeMinutes: 5,
      tags: ['popular'],
    ),
    const MenuItem(
      id: 'mi-602',
      name: 'Chocolate Fondant',
      categoryId: 'cat-6',
      price: 8.00,
      description: 'Warm chocolate fondant with vanilla ice cream.',
      isVegetarian: true,
      allergens: ['dairy', 'eggs', 'gluten'],
      preparationTimeMinutes: 12,
    ),
    // Beverages
    const MenuItem(
      id: 'mi-701',
      name: 'Sparkling Water (500ml)',
      categoryId: 'cat-7',
      price: 2.50,
      isVegan: true,
      preparationTimeMinutes: 1,
    ),
    const MenuItem(
      id: 'mi-702',
      name: 'Fresh Orange Juice',
      categoryId: 'cat-7',
      price: 3.50,
      isVegan: true,
      preparationTimeMinutes: 3,
    ),
    const MenuItem(
      id: 'mi-703',
      name: 'Espresso',
      categoryId: 'cat-7',
      price: 2.80,
      isVegetarian: true,
      preparationTimeMinutes: 3,
    ),
    const MenuItem(
      id: 'mi-704',
      name: 'House Red Wine (Glass)',
      categoryId: 'cat-7',
      price: 6.50,
      isVegan: true,
      preparationTimeMinutes: 1,
    ),
  ];

  // ── Tables ────────────────────────────────────────────────────────────────
  static final List<RestaurantTable> tables = [
    // Indoor section
    const RestaurantTable(id: 't-01', number: 1, capacity: 2, section: 'Indoor', status: TableStatus.available),
    const RestaurantTable(id: 't-02', number: 2, capacity: 4, section: 'Indoor', status: TableStatus.occupied, currentOrderId: 'ord-001'),
    const RestaurantTable(id: 't-03', number: 3, capacity: 4, section: 'Indoor', status: TableStatus.occupied, currentOrderId: 'ord-002'),
    const RestaurantTable(id: 't-04', number: 4, capacity: 6, section: 'Indoor', status: TableStatus.available),
    const RestaurantTable(id: 't-05', number: 5, capacity: 2, section: 'Indoor', status: TableStatus.reserved, reservedFor: 'Johnson'),
    const RestaurantTable(id: 't-06', number: 6, capacity: 4, section: 'Indoor', status: TableStatus.cleaning),
    const RestaurantTable(id: 't-07', number: 7, capacity: 8, section: 'Indoor', status: TableStatus.available),
    const RestaurantTable(id: 't-08', number: 8, capacity: 4, section: 'Indoor', status: TableStatus.occupied, currentOrderId: 'ord-003'),
    // Terrace section
    const RestaurantTable(id: 't-09', number: 9, capacity: 2, section: 'Terrace', status: TableStatus.available),
    const RestaurantTable(id: 't-10', number: 10, capacity: 4, section: 'Terrace', status: TableStatus.occupied, currentOrderId: 'ord-004'),
    const RestaurantTable(id: 't-11', number: 11, capacity: 4, section: 'Terrace', status: TableStatus.available),
    const RestaurantTable(id: 't-12', number: 12, capacity: 6, section: 'Terrace', status: TableStatus.reserved, reservedFor: 'Smith Party'),
  ];

  // ── Active orders ─────────────────────────────────────────────────────────
  static List<Order> get orders => [
        Order(
          id: 'ord-001',
          tableId: 't-02',
          tableNumber: 2,
          status: OrderStatus.preparing,
          createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
          items: [
            OrderItem(id: 'oi-1', menuItem: menuItems[0], quantity: 2),
            OrderItem(id: 'oi-2', menuItem: menuItems[4], quantity: 1),
            OrderItem(id: 'oi-3', menuItem: menuItems[14], quantity: 2),
          ],
        ),
        Order(
          id: 'ord-002',
          tableId: 't-03',
          tableNumber: 3,
          status: OrderStatus.ready,
          createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
          items: [
            OrderItem(id: 'oi-4', menuItem: menuItems[8], quantity: 1, notes: 'Medium rare'),
            OrderItem(id: 'oi-5', menuItem: menuItems[10], quantity: 1),
            OrderItem(id: 'oi-6', menuItem: menuItems[16], quantity: 2),
          ],
        ),
        Order(
          id: 'ord-003',
          tableId: 't-08',
          tableNumber: 8,
          status: OrderStatus.pending,
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          items: [
            OrderItem(id: 'oi-7', menuItem: menuItems[5], quantity: 2),
            OrderItem(id: 'oi-8', menuItem: menuItems[13], quantity: 2),
            OrderItem(id: 'oi-9', menuItem: menuItems[17], quantity: 4),
          ],
        ),
        Order(
          id: 'ord-004',
          tableId: 't-10',
          tableNumber: 10,
          status: OrderStatus.preparing,
          createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
          items: [
            OrderItem(id: 'oi-10', menuItem: menuItems[11], quantity: 2),
            OrderItem(id: 'oi-11', menuItem: menuItems[2], quantity: 2),
            OrderItem(id: 'oi-12', menuItem: menuItems[14], quantity: 2),
          ],
        ),
      ];

  // ── Dashboard stats ───────────────────────────────────────────────────────
  static const Map<String, dynamic> dashboardStats = {
    'totalRevenue': 3842.50,
    'totalOrders': 47,
    'avgOrderValue': 81.75,
    'tablesOccupied': 5,
    'totalTables': 12,
    'popularItem': 'Chicken Tikka Masala',
  };
}
