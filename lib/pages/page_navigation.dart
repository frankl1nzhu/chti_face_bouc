import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services_firebase/service_authentification.dart';
import '../services_firebase/service_firestore.dart';
import '../modeles/membre.dart'; // Import Membre model
import '../widgets/widget_vide.dart'; // Import helper widgets
// Import page widgets (PageAccueil, PageMembres, PageEcrirePost, PageNotif, PageProfil)
import 'page_accueil.dart';
import 'page_membres.dart';
import 'page_ecrire_post.dart';
import 'page_profil.dart';

class PageNavigation extends StatefulWidget {
  const PageNavigation({super.key});

  @override
  State<PageNavigation> createState() => _PageNavigationState();
}

class _PageNavigationState extends State<PageNavigation> {
  int index = 0; // Current page index

  @override
  Widget build(BuildContext context) {
    final memberId = ServiceAuthentification().myId;
    print("Current memberId: $memberId"); // Debug print

    if (memberId == null) {
      // 如果没有登录，显示登录提示
      print("No memberId found, showing login page");
      return Scaffold(
        appBar: AppBar(title: const Text("Authentification")),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Veuillez vous connecter pour accéder à l'application"),
              SizedBox(height: 20),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    // 使用FutureBuilder先检查文档是否存在
    return FutureBuilder<DocumentSnapshot>(
      future: ServiceFirestore().firestoreMember.doc(memberId).get(),
      builder: (context, docSnapshot) {
        print(
          "FutureBuilder state: ${docSnapshot.connectionState}, hasData: ${docSnapshot.hasData}",
        );

        // 如果正在加载，显示加载界面
        if (docSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text("Chargement...")),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // 处理错误
        if (docSnapshot.hasError) {
          print("FutureBuilder error: ${docSnapshot.error}");
          return Scaffold(
            appBar: AppBar(
              title: const Text("Erreur"),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await ServiceAuthentification().signOut();
                  },
                ),
              ],
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Erreur de chargement: ${docSnapshot.error}",
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Retry by rebuilding
                    },
                    child: const Text("Réessayer"),
                  ),
                ],
              ),
            ),
          );
        }

        // 再次检查用户ID是否有效 (可能在获取数据期间发生变化)
        final currentMemberId = ServiceAuthentification().myId;
        if (currentMemberId == null || currentMemberId != memberId) {
          print("User ID changed during data loading, rebuilding");
          Future.microtask(() => setState(() {}));
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 检查文档是否存在
        if (!docSnapshot.hasData || !docSnapshot.data!.exists) {
          print("Document doesn't exist for ID: $memberId - creating new user");
          // 创建一个新的用户记录
          Map<String, dynamic> defaultUserData = {
            "name": "",
            "surname": "",
            "profilePicture": "",
            "coverPicture": "",
            "description": "",
          };

          // 创建文档
          ServiceFirestore()
              .addMember(id: memberId, data: defaultUserData)
              .then((_) {
                print("User document created successfully");
                if (mounted) setState(() {});
              })
              .catchError((error) {
                print("Error creating user document: $error");
              });

          // 显示创建配置文件的界面
          return Scaffold(
            appBar: AppBar(
              title: const Text("Nouveau profil"),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await ServiceAuthentification().signOut();
                  },
                ),
              ],
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Création de votre profil..."),
                ],
              ),
            ),
          );
        }

        // 文档存在，使用StreamBuilder监听实时更新
        return StreamBuilder<DocumentSnapshot>(
          stream: ServiceFirestore().specificMember(memberId),
          builder: (
            BuildContext context,
            AsyncSnapshot<DocumentSnapshot> snapshot,
          ) {
            // Debug prints
            print("StreamBuilder state: ${snapshot.connectionState}");
            if (snapshot.hasError) {
              print("StreamBuilder error: ${snapshot.error}");
            }

            // 最终检查用户ID是否仍然有效
            final finalMemberId = ServiceAuthentification().myId;
            if (finalMemberId == null || finalMemberId != memberId) {
              print("User ID changed before display, rebuilding");
              Future.microtask(() => setState(() {}));
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // 检查连接状态
            if (snapshot.connectionState == ConnectionState.waiting) {
              // 使用已获取的文档数据构建Membre，而不是显示加载界面
              // 这避免了切换时的闪烁
              try {
                final data = docSnapshot.data!;
                print("Using cached document data");
                final Membre member = Membre(
                  reference: data.reference,
                  id: data.id,
                  map: data.data() as Map<String, dynamic>,
                );

                return buildScaffoldWithMember(member);
              } catch (e) {
                print("Error using cached data: $e");
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
            }

            // 处理错误或空数据
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data?.data() == null) {
              print("Error or empty data in stream: ${snapshot.error}");

              // 尝试使用缓存的文档数据
              try {
                final data = docSnapshot.data!;
                print("Using cached document data on error");
                final Membre member = Membre(
                  reference: data.reference,
                  id: data.id,
                  map: data.data() as Map<String, dynamic>,
                );

                return buildScaffoldWithMember(member);
              } catch (e) {
                print("Error using cached data on error: $e");

                // 显示错误信息
                return Scaffold(
                  appBar: AppBar(
                    title: const Text("Erreur"),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () async {
                          await ServiceAuthentification().signOut();
                        },
                      ),
                    ],
                  ),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Erreur de chargement du profil: ${snapshot.error}",
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Retry
                          },
                          child: const Text("Réessayer"),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }

            // 有数据，创建Membre对象
            try {
              final data = snapshot.data!;
              print("Creating member from stream data: ${data.id}");
              final Membre member = Membre(
                reference: data.reference,
                id: data.id,
                map: data.data() as Map<String, dynamic>,
              );

              print("Member created successfully: ${member.fullName}");
              return buildScaffoldWithMember(member);
            } catch (e) {
              print("Exception in PageNavigation build: $e");

              // 尝试使用缓存的文档数据
              try {
                final data = docSnapshot.data!;
                print("Using cached document data after exception");
                final Membre member = Membre(
                  reference: data.reference,
                  id: data.id,
                  map: data.data() as Map<String, dynamic>,
                );

                return buildScaffoldWithMember(member);
              } catch (fallbackError) {
                // 显示错误信息
                return Scaffold(
                  appBar: AppBar(
                    title: const Text("Erreur"),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () async {
                          await ServiceAuthentification().signOut();
                        },
                      ),
                    ],
                  ),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Erreur lors du chargement: $e",
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Retry
                          },
                          child: const Text("Réessayer"),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  // 提取构建Scaffold的方法
  Widget buildScaffoldWithMember(Membre member) {
    // 定义导航栏的页面
    List<Widget> bodies = [
      const PageAccueil(title: "Accueil"), // 首页
      const PageMembres(), // 成员页面
      PageEcrirePost(
        member: member,
        newSelection: (int index) {
          setState(() {
            this.index = index;
          });
        },
      ), // 写帖子页面
      const Center(child: Text("Notifications")), // 通知占位符
      PageProfil(member: member), // 带有当前用户的个人资料页面
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          member.fullName.isNotEmpty ? member.fullName : "Cht'i Face Bouc",
        ), // 显示用户名或默认标题
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ServiceAuthentification().signOut();
            },
          ),
        ],
      ),
      body: bodies[index], // 显示选定的页面
      bottomNavigationBar: NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        selectedIndex: index,
        onDestinationSelected: (int newValue) {
          setState(() {
            index = newValue; // 更新选定的索引
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: "Accueil"),
          NavigationDestination(icon: Icon(Icons.group), label: "Membres"),
          NavigationDestination(
            icon: Icon(Icons.border_color),
            label: "Ecrire",
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications),
            label: "Notification",
          ),
          NavigationDestination(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}
