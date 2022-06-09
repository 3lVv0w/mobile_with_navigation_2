import 'package:flutter/material.dart';

void main() => runApp(const NestedRouterDemo());

//Model???
class Book {
  final String title;
  final String author;

  Book(this.title, this.author);
}

//Main app Class must be statefull
class NestedRouterDemo extends StatefulWidget {
  const NestedRouterDemo({Key? key}) : super(key: key);

  @override
  _NestedRouterDemoState createState() => _NestedRouterDemoState();
}

class _NestedRouterDemoState extends State<NestedRouterDemo> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routeInformationParser: BookRouteInformationParser(),
      routerDelegate: BookRouterDelegate(),
    );
  }
}

//App state
class BookAppState extends ChangeNotifier {
  int _selectedPageIndex;
  Book? _selectedBook;

  final List<Book> books = [
    Book('Sítio do picapau amarelo', 'Monteiro Lobato'),
    Book('Memórias Póstunas de Brás Cubas', 'Machado de Assis'),
    Book('Capitães de reia', 'Jorge Amado')
  ];

  BookAppState() : _selectedPageIndex = 0;

  //Index Getter and setters
  int get selectedPageIndex => _selectedPageIndex;

  set selectedPageIndex(int index) {
    _selectedPageIndex = index;

    if (_selectedPageIndex == 1) {
      //Remove to keep the selected book
      selectedBook = null;
    }
    notifyListeners();
  }

  //Book Getter and setters
  Book? get selectedBook => _selectedBook;

  set selectedBook(Book? book) {
    _selectedBook = book;
    notifyListeners();
  }

  int getSelectedBookById() {
    if (!books.contains(_selectedBook) || _selectedBook == null) {
      return 0;
    }

    return books.indexOf(_selectedBook!);
  }

  void setSelectedBookById(int id) {
    if (id < 0 || id > books.length - 1) {
      return;
    }

    _selectedBook = books[id];
    notifyListeners();
  }
}

//Parser mandatory
class BookRouteInformationParser extends RouteInformationParser<BookRoutePath> {
  @override
  Future<BookRoutePath> parseRouteInformation(
      RouteInformation routeInformation) async {
    //Parse URL
    final uri = Uri.parse(routeInformation.location!);

    //Return Settings page path
    if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'settings') {
      return BooksSettingsPath();
    } else {
      // Return Book path
      if (uri.pathSegments.length >= 2) {
        if (uri.pathSegments[0] == 'book') {
          return BooksDetailsPath(int.tryParse(uri.pathSegments[1])!);
        }
      }
      //Anything else, return Homepage
      return BooksListPath();
    }
  }

  //TODO: search
  @override
  RouteInformation? restoreRouteInformation(BookRoutePath configuration) {
    if (configuration is BooksListPath) {
      return const RouteInformation(location: '/home');
    }
    if (configuration is BooksSettingsPath) {
      return const RouteInformation(location: '/settings');
    }
    if (configuration is BooksDetailsPath) {
      return RouteInformation(location: '/book/${configuration.id}');
    }
    return null;
  }
}

///
//  Delegate route
///
class BookRouterDelegate extends RouterDelegate<BookRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<BookRoutePath> {
  @override
  final GlobalKey<NavigatorState> navigatorKey;

  //New app state
  BookAppState appState = BookAppState();

  //Constructor (to search)
  BookRouterDelegate() : navigatorKey = GlobalKey<NavigatorState>() {
    appState.addListener(notifyListeners);
  }

//To search
  @override
  BookRoutePath get currentConfiguration {
    if (appState.selectedPageIndex == 1) {
      return BooksSettingsPath();
    } else {
      if (appState.selectedBook == null) {
        return BooksListPath();
      } else {
        return BooksDetailsPath(appState.getSelectedBookById());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [
        MaterialPage(child: AppShell(appState: appState)),
      ],
      onPopPage: (route, result) {
        return route.didPop(result);
      },
    );
  }

  @override
  Future<void> setNewRoutePath(BookRoutePath configuration) async {
    if (configuration is BooksListPath) {
      appState.selectedPageIndex = 0;
      appState.selectedBook = null;
    } else if (configuration is BooksSettingsPath) {
      appState.selectedPageIndex = 1;
    } else if (configuration is BooksDetailsPath) {
      appState.selectedPageIndex = 0;
      appState.setSelectedBookById(configuration.id);
    }
  }
}

//Routes
abstract class BookRoutePath {}

class BooksListPath extends BookRoutePath {}

class BooksSettingsPath extends BookRoutePath {}

class BooksDetailsPath extends BookRoutePath {
  final int id;
  BooksDetailsPath(this.id);
}

//Pages widget that contains
class AppShell extends StatefulWidget {
  final BookAppState appState;

  const AppShell({
    Key? key,
    required this.appState,
  }) : super(key: key);

  @override
  _AppShellState createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late InnerRouterDelegate _routerDelegate;
  late ChildBackButtonDispatcher _backButtonDispatcher;

  @override
  void initState() {
    super.initState();
    _routerDelegate = InnerRouterDelegate(widget.appState);
  }

  //TODO: search
  @override
  void didUpdateWidget(covariant oldWidget) {
    super.didUpdateWidget(oldWidget);

    _routerDelegate.appState = widget.appState;
  }

  // TODO: search
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Defer back button dispatching to the child router
    _backButtonDispatcher = Router.of(context)
        .backButtonDispatcher!
        .createChildBackButtonDispatcher();
  }

  @override
  Widget build(BuildContext context) {
    var appState = widget.appState;

    //Claim priority, If there are parallel sub router, you will need
    //To pick which  one should take priority;
    _backButtonDispatcher.takePriority();
    return Scaffold(
      appBar: appState.selectedBook != null
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _routerDelegate.popRoute(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {},
                )
              ],
            )
          : AppBar(),
      body: Router(
        routerDelegate: _routerDelegate,
        backButtonDispatcher: _backButtonDispatcher,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: appState.selectedPageIndex,
        onTap: (newIndex) {
          appState.selectedPageIndex = newIndex;
        },
      ),
    );
  }
}

class InnerRouterDelegate extends RouterDelegate<BookRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<BookRoutePath> {
  @override
  final navigatorKey = GlobalKey<NavigatorState>();
  BookAppState _appState;

  BookAppState get appState => _appState;
  set appState(BookAppState value) {
    if (value == _appState) {
      return;
    }
    _appState = value;
    notifyListeners();
  }

  InnerRouterDelegate(this._appState);

  @override
  Widget build(BuildContext context) {
    print(appState.selectedPageIndex);
    return Navigator(
      key: navigatorKey,
      pages: [
        if (appState.selectedPageIndex == 0) ...[
          FadeAnimationPage(
            child: BookListScreen(
              books: appState.books,
              onTapped: _handleBookTapped,
            ),
            key: const ValueKey('BooksListPage'),
          ),
          if (appState.selectedBook != null)
            MaterialPage(
              key: ValueKey(appState.selectedBook),
              child: BookDetailsScreen(
                book: appState.selectedBook,
              ),
            ),
        ] else
          const FadeAnimationPage(
            key: ValueKey('SettingsPage'),
            child: SettingsScreen(),
          )
      ],
      onPopPage: (route, result) {
        appState.selectedBook = null;
        notifyListeners();
        return route.didPop(result);
      },
    );
  }

  @override
  Future<void> setNewRoutePath(BookRoutePath configuration) {
    //Don't need to be implemented, Because Parent already delegates URI
    // TODO: implement setNewRoutePath
    throw UnimplementedError();
  }

  void _handleBookTapped(Book book) {
    appState.selectedBook = book;
    notifyListeners();
  }
}

////
// Pages and screens
///
class FadeAnimationPage extends Page {
  final Widget? child;

  const FadeAnimationPage({
    Key? key,
    this.child,
  });

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      pageBuilder: (context, animation, animation2) {
        var curveTween = CurveTween(curve: Curves.easeIn);
        return FadeTransition(
          opacity: animation.drive(curveTween),
          child: child,
        );
      },
    );
  }
}

class BookListScreen extends StatelessWidget {
  final List<Book> books;
  final ValueChanged<Book> onTapped;

  const BookListScreen({
    Key? key,
    required this.books,
    required this.onTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.separated(
        itemCount: books.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(books[index].title),
            subtitle: Text(books[index].author),
            onTap: () => onTapped(books[index]),
          );
        },
        separatorBuilder: (context, index) => const Divider(),
      ),
    );
  }
}

class BookDetailsScreen extends StatelessWidget {
  final Book? book;

  const BookDetailsScreen({
    Key? key,
    this.book,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (book != null) ...[
              Text(
                book!.title,
                style: Theme.of(context).textTheme.headline6,
              ),
              Text(
                book!.author,
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Settings'),
      ),
    );
  }
}

//TODO: Edit screen

class BookEditScreen extends StatelessWidget {
  final Book? book;

  const BookEditScreen({
    Key? key,
    this.book,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (book != null) ...[
              Text(
                book!.title,
                style: Theme.of(context).textTheme.headline6,
              ),
              Text(
                book!.author,
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ]
          ],
        ),
      ),
    );
  }
}
