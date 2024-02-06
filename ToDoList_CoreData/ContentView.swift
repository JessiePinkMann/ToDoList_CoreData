import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TodoItem.dateAdded, ascending: true)],
        animation: .default)
    private var items: FetchedResults<TodoItem>
    @State private var showingAddTask = false
    @State private var editingTask: TodoItem?

    var body: some View {
        NavigationView {
            List {
                ForEach(items) { item in
                    HStack {
                        Text(item.title ?? "Untitled")
                            .onTapGesture {
                                self.editingTask = item
                            }
                        Spacer()
                        Button(action: {
                            item.isCompleted.toggle()
                            saveContext()
                        }) {
                            Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                                .foregroundColor(item.isCompleted ? .blue : .gray)
                                .font(.system(size: 24))
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationBarTitle("ToDo List")
            .navigationBarItems(trailing: Button(action: {
                showingAddTask = true
            }) {
                Text("Add Task")
            })
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(context: viewContext) {
                    self.showingAddTask = false
                }
            }
            .sheet(item: $editingTask) { item in
                EditTaskView(item: item) {
                    self.editingTask = nil
                }
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            saveContext()
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    var context: NSManagedObjectContext
    var completion: () -> Void
    @State private var taskTitle = ""

    var body: some View {
        NavigationView {
            VStack {
                TextField("Name your task", text: $taskTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .padding(.horizontal, 40)
                    Spacer()
                    Button("Add") {
                        let newTask = TodoItem(context: context)
                        newTask.id = UUID()
                        newTask.title = taskTitle
                        newTask.dateAdded = Date()
                        newTask.isCompleted = false
                        try? context.save()
                        completion()
                        dismiss()
                    }
                    .disabled(taskTitle.isEmpty)
                    .padding(.horizontal, 40)
                }
                .padding(.horizontal)
            }
            .navigationBarHidden(true)
        }
    }
}

struct EditTaskView: View {
    var item: TodoItem
    var completion: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var taskTitle: String

    init(item: TodoItem, completion: @escaping () -> Void) {
        self.item = item
        self.completion = completion
        _taskTitle = State(initialValue: item.title ?? "")
    }

    var body: some View {
        NavigationView {
            VStack {
                TextField("", text: $taskTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .padding(.horizontal, 40)
                    Spacer()
                    Button("Rename") {
                        item.title = taskTitle
                        try? item.managedObjectContext?.save()
                        completion()
                        dismiss()
                    }
                    .disabled(taskTitle.isEmpty)
                    .padding(.horizontal, 40)
                }
                .padding(.horizontal)
            }
            .navigationBarHidden(true)
        }
    }
}
