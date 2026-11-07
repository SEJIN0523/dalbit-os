// 지금 쓰고 있는 앱 이름 (맥의 메뉴 막대처럼 굵게)
// 작업 관리자 부품을 이 파일에서만 불러와, 혹시 불러오지 못해도 달 메뉴는 그대로 동작
import QtQuick
import org.kde.taskmanager as TaskManager

Item {
    id: root

    property string fallback: "바탕화면"
    readonly property string text: name !== "" ? name : fallback
    property string name: ""

    function update() {
        const idx = tasks.activeTask
        if (!idx || !idx.valid) {
            name = ""
            return
        }
        const n = tasks.data(idx, TaskManager.AbstractTasksModel.AppName)
        // Plasma 자신(바탕화면·위젯 창)은 앱 이름 대신 기본 문구
        const id = tasks.data(idx, TaskManager.AbstractTasksModel.AppId) || ""
        name = (id === "org.kde.plasmashell" || !n) ? "" : n
    }

    TaskManager.TasksModel {
        id: tasks
        groupMode: TaskManager.TasksModel.GroupDisabled
        onActiveTaskChanged: root.update()
        onDataChanged: root.update()
    }

    Component.onCompleted: update()
}
