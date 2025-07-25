import UIKit
import PieChart

class AnalysisViewController: UIViewController {
    private var startDate: Date = Date()
    private var endDate: Date = Date()
    private let allTransactions: [Transaction]
    private let categories: [Category]
    private var transactions: [Transaction] = []
    {
      didSet { updateChart() }
    }
    private var sortedBy: SortOption = .date

    private enum SortOption {
        case date, amount
    }
    
    private let pieChartView: PieChartView = {
      let v = PieChartView()
      v.translatesAutoresizingMaskIntoConstraints = false
      v.backgroundColor = .clear
      return v
    }()

    private let loadingOverlay: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()
    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .large)
        ai.color = .gray
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()
    private func setupLoadingOverlay() {
        view.addSubview(loadingOverlay)
        loadingOverlay.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            loadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            loadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: loadingOverlay.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: loadingOverlay.centerYAnchor)
        ])
    }
    private func setLoading(_ loading: Bool) {
        loadingOverlay.isHidden = !loading
        if loading { activityIndicator.startAnimating() }
        else      { activityIndicator.stopAnimating() }
    }

    init(transactions: [Transaction], categories: [Category]) {
        self.allTransactions = transactions
        self.categories = categories
        super.init(nibName: nil, bundle: nil)
        if let minDate = transactions.map({ $0.transactionDate }).min() {
            self.startDate = minDate
        }
        if let maxDate = transactions.map({ $0.transactionDate }).max() {
            self.endDate = maxDate
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var sortButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.tintColor = .black
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .light)
        btn.setImage(UIImage(systemName: "arrow.up.arrow.down", withConfiguration: config), for: .normal)
        btn.addTarget(self, action: #selector(sortButtonTapped), for: .touchUpInside)
        return btn
    }()

    private lazy var sortLable: UILabel = {
        let label = UILabel()
        label.text = "Сортировка"
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var periodView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var startLabel: UILabel = {
        let label = UILabel()
        label.text = "Начало"
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var sumLabel: UILabel = {
        let label = UILabel()
        label.text = "Сумма"
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var startDateButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.titleLabel?.font = .systemFont(ofSize: 16)
        btn.setTitleColor(.black, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(selectStartDate), for: .touchUpInside)
        return btn
    }()

    private lazy var endLabel: UILabel = {
        let label = UILabel()
        label.text = "Конец"
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var endDateButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.titleLabel?.font = .systemFont(ofSize: 16)
        btn.setTitleColor(.black, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(selectEndDate), for: .touchUpInside)
        return btn
    }()

    private lazy var amountLabel: UILabel = {
        let label = UILabel()
        label.text = "0 ₽"
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Анализ"
        label.textColor = .label
        label.font = UIFont.systemFont(ofSize: 35, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var operationsLabel: UILabel = {
        let label = UILabel()
        label.text = "ОПЕРАЦИИ"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var operationsContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private lazy var contentContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.dataSource = self
        tv.delegate = self
        tv.register(TransactionCell.self, forCellReuseIdentifier: "TransactionCell")
        tv.separatorStyle = .singleLine
        tv.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tv.backgroundColor = .clear
        tv.tableFooterView = UIView()
        tv.isScrollEnabled = false
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 60
        return tv
    }()

    private var tableHeightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLoadingOverlay()
        filterAndReload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.layoutIfNeeded()
        tableHeightConstraint?.constant = tableView.contentSize.height
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground

        startDateButton.setTitle(formatDate(startDate), for: .normal)
        endDateButton.setTitle(formatDate(endDate), for: .normal)

        view.addSubview(titleLabel)
//        view.addSubview(pieChartView)

        view.addSubview(scrollView)
        scrollView.addSubview(contentContainer)

        contentContainer.addSubview(periodView)
        let vs = UIStackView(arrangedSubviews: [
            makeRow(title: startLabel, value: startDateButton, isLast: false),
            makeRow(title: endLabel,   value: endDateButton,   isLast: false),
            makeRow(title: sortLable,  value: sortButton,      isLast: false),
            makeRow(title: sumLabel,   value: amountLabel,     isLast: true)
        ])
        vs.axis = .vertical
        vs.spacing = 10
        vs.translatesAutoresizingMaskIntoConstraints = false
        periodView.addSubview(vs)

        contentContainer.addSubview(operationsLabel)
        contentContainer.addSubview(operationsContainer)
        contentContainer.addSubview(pieChartView)

        operationsContainer.addSubview(tableView)

        tableHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
        tableHeightConstraint?.isActive = true
       
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            
            pieChartView.topAnchor.constraint(equalTo: periodView.bottomAnchor, constant: 16),
                    // leading/trailing во всю ширину
                    pieChartView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 16),
                    pieChartView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -16),
                    // фиксированная высота или пропорция
                    pieChartView.heightAnchor.constraint(equalTo: pieChartView.widthAnchor, multiplier: 0.6),

            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentContainer.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentContainer.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            periodView.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 24),
            periodView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 16),
            periodView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -16),

            vs.topAnchor.constraint(equalTo: periodView.topAnchor, constant: 8),
            vs.leadingAnchor.constraint(equalTo: periodView.leadingAnchor, constant: 16),
            vs.trailingAnchor.constraint(equalTo: periodView.trailingAnchor, constant: -16),
            vs.bottomAnchor.constraint(equalTo: periodView.bottomAnchor, constant: -8),

            operationsLabel.topAnchor.constraint(equalTo: pieChartView.bottomAnchor, constant: 16),
            operationsLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 32),
            

            operationsContainer.topAnchor.constraint(equalTo: operationsLabel.bottomAnchor, constant: 6),
            operationsContainer.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 16),
            operationsContainer.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -16),
            

            tableView.topAnchor.constraint(equalTo: operationsContainer.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: operationsContainer.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: operationsContainer.trailingAnchor),
            operationsContainer.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),

            contentContainer.bottomAnchor.constraint(equalTo: operationsContainer.bottomAnchor)
        ])
//        operationsLabel.topAnchor.constraint(equalTo: pieChartView.bottomAnchor, constant: 16).isActive = true

    }

    private func filterAndReload() {
        setLoading(true)
        transactions = allTransactions.filter {
            $0.transactionDate >= startDate && $0.transactionDate <= endDate
        }
        updateTotalAmount()
        sortTransactions()
        setLoading(false)
    }

    private func updateTotalAmount() {
        let totalAmount = transactions.reduce(Decimal(0)) { $0 + $1.amount }
        amountLabel.text = "\(formatAmount(totalAmount)) ₽"
    }

    private func updateChart() {
      // Сгруппировали суммы по категориям
      let sums = Dictionary(grouping: transactions) { $0.categoryId }
        .mapValues { $0.map(\.amount).reduce(0, +) }

      // Сконвертировали в Entity
      var ents: [Entity] = categories.compactMap { cat in
        guard let sum = sums[cat.id], sum > 0 else { return nil }
        return Entity(value: sum, label: cat.name)
      }
      // Отсортировали
      ents.sort { $0.value > $1.value }

      // Передали в PieChartView — это вызовет setNeedsDisplay()
      pieChartView.entities = ents
    }
    private func sortTransactions() {
        switch sortedBy {
        case .date:
            transactions.sort { $0.transactionDate > $1.transactionDate }
        case .amount:
            transactions.sort { $0.amount > $1.amount }
        }
        tableView.reloadData()
        tableView.layoutIfNeeded()
        tableHeightConstraint?.constant = tableView.contentSize.height
    }

    @objc private func sortButtonTapped() {
        let alert = UIAlertController(title: "Сортировка", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "По дате", style: .default) { [weak self] _ in
            self?.sortedBy = .date; self?.sortTransactions()
        })
        alert.addAction(UIAlertAction(title: "По сумме", style: .default) { [weak self] _ in
            self?.sortedBy = .amount; self?.sortTransactions()
        })
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func selectStartDate() { showSwiftUIStyleDatePicker(isStart: true) }
    @objc private func selectEndDate()   { showSwiftUIStyleDatePicker(isStart: false) }

    private func showSwiftUIStyleDatePicker(isStart: Bool) {
        let datePickerVC = SwiftUIStyleDatePickerViewController()
        datePickerVC.currentDate = isStart ? startDate : endDate
        datePickerVC.title = isStart ? "Выберите начальную дату" : "Выберите конечную дату"
        datePickerVC.modalPresentationStyle = .pageSheet

        if #available(iOS 15.0, *) {
            datePickerVC.sheetPresentationController?.detents = [.medium()]
            datePickerVC.sheetPresentationController?.prefersGrabberVisible = true
        }

        datePickerVC.onDateSelected = { [weak self] selectedDate in
            guard let self = self else { return }
            if isStart {
                self.startDate = selectedDate
                self.startDateButton.setTitle(self.formatDate(selectedDate), for: .normal)
                if selectedDate > self.endDate {
                    self.endDate = selectedDate
                    self.endDateButton.setTitle(self.formatDate(selectedDate), for: .normal)
                }
            } else {
                self.endDate = selectedDate
                self.endDateButton.setTitle(self.formatDate(selectedDate), for: .normal)
                if selectedDate < self.startDate {
                    self.startDate = selectedDate
                    self.startDateButton.setTitle(self.formatDate(selectedDate), for: .normal)
                }
            }
            self.filterAndReload()
        }

        if let pop = datePickerVC.popoverPresentationController {
            let sourceButton = isStart ? startDateButton : endDateButton
            pop.sourceView = sourceButton
            pop.sourceRect = sourceButton.bounds
            pop.permittedArrowDirections = .up
        }

        present(datePickerVC, animated: true)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }

    private func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }
}

class SwiftUIStyleDatePickerViewController: UIViewController {
    var currentDate: Date = Date()
    var onDateSelected: ((Date) -> Void)?
    
    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.locale = Locale(identifier: "ru_RU")
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    private lazy var calendarView: UICalendarView = {
        let calendar = UICalendarView()
        calendar.translatesAutoresizingMaskIntoConstraints = false
        calendar.calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ru_RU")
        calendar.fontDesign = .default
        return calendar
    }()
    
    private lazy var doneButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Готово", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var cancelButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Отмена", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17)
        btn.setTitleColor(.systemBlue, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        return btn
    }()
    
    @available(iOS 16.0, *)
    private var singleDateSelection: UICalendarSelectionSingleDate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCalendar()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(titleLabel)
        view.addSubview(calendarView)
        view.addSubview(doneButton)
        view.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            calendarView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            calendarView.heightAnchor.constraint(equalToConstant: 300),
            
            doneButton.topAnchor.constraint(equalTo: calendarView.bottomAnchor, constant: 30),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.heightAnchor.constraint(equalToConstant: 50),
            
            cancelButton.topAnchor.constraint(equalTo: doneButton.bottomAnchor, constant: 10),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @available(iOS 16.0, *)
    private func setupCalendar() {
        guard #available(iOS 16.0, *) else {
            setupFallbackDatePicker()
            return
        }
        
        let selection = UICalendarSelectionSingleDate(delegate: self)
        calendarView.selectionBehavior = selection
        singleDateSelection = selection
        
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: currentDate)
        selection.selectedDate = dateComponents
        
        calendarView.availableDateRange = DateInterval(start: .distantPast, end: .distantFuture)
    }
    
    private func setupFallbackDatePicker() {
        calendarView.removeFromSuperview()
        
        datePicker.date = currentDate
        view.addSubview(datePicker)
        
        NSLayoutConstraint.activate([
            datePicker.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            datePicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            doneButton.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 50)
        ])
    }
    
    @objc private func doneButtonTapped() {
        let selectedDate: Date
        
        if #available(iOS 16.0, *), let dateComponents = singleDateSelection?.selectedDate {
            selectedDate = Calendar.current.date(from: dateComponents) ?? currentDate
        } else {
            selectedDate = datePicker.date
        }
        
        onDateSelected?(selectedDate)
        dismiss(animated: true)
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
}

@available(iOS 16.0, *)
extension SwiftUIStyleDatePickerViewController: UICalendarSelectionSingleDateDelegate {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, canSelectDate dateComponents: DateComponents?) -> Bool {
        return true
    }
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        
    }
}

extension AnalysisViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionCell", for: indexPath) as! TransactionCell
        let transaction = transactions[indexPath.row]
        let category = categories.first { $0.id == transaction.categoryId }
        cell.configure(with: transaction, category: category, totalAmount: transactions.reduce(0) { $0 + $1.amount })
        
        if indexPath.row == transactions.count - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }
        
        return cell
    }
}

class TransactionCell: UITableViewCell {
    private let emojiContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.systemGray6
        view.layer.cornerRadius = 16
        return view
    }()
    
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 18)
        label.textAlignment = .center
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .label
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let percentLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .right
        return label
    }()
    
    private let amountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .right
        return label
    }()
    
    private let chevronImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .tertiaryLabel
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .none
        backgroundColor = .clear
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(emojiContainer)
        emojiContainer.addSubview(emojiLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(percentLabel)
        contentView.addSubview(amountLabel)
        contentView.addSubview(chevronImageView)
        
        NSLayoutConstraint.activate([
            emojiContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            emojiContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            emojiContainer.widthAnchor.constraint(equalToConstant: 32),
            emojiContainer.heightAnchor.constraint(equalToConstant: 32),
            
            emojiLabel.centerXAnchor.constraint(equalTo: emojiContainer.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: emojiContainer.centerYAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: emojiContainer.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: percentLabel.leadingAnchor, constant: -8),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: amountLabel.leadingAnchor, constant: -8),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            chevronImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            percentLabel.topAnchor.constraint(equalTo: titleLabel.topAnchor),
            percentLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -4),
            
            amountLabel.topAnchor.constraint(equalTo: percentLabel.bottomAnchor, constant: 2),
            amountLabel.trailingAnchor.constraint(equalTo: percentLabel.trailingAnchor)
        ])
    }
    
    func configure(with transaction: Transaction, category: Category?, totalAmount: Decimal) {
        if let cat = category {
            emojiLabel.text = String(cat.emoji)
            titleLabel.text = cat.name
        } else {
            emojiLabel.text = "💸"
            titleLabel.text = transaction.comment ?? "Операция"
        }
        
        subtitleLabel.text = transaction.comment ?? "Без описания"
        
        let percent: Double
        if totalAmount != 0 {
            let ratio = (transaction.amount / totalAmount) as NSDecimalNumber
            percent = ratio.doubleValue * 100
        } else {
            percent = 0
        }
        percentLabel.text = String(format: "%.0f%%", percent)
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 2
        let amountString = formatter.string(from: transaction.amount as NSDecimalNumber) ?? "\(transaction.amount)"
        amountLabel.text = "\(amountString) ₽"
    }
}

extension AnalysisViewController {
    private func makeRow(title: UILabel, value: UIView, isLast: Bool) -> UIStackView {
        let contentStack = UIStackView()
        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = 8
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        title.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        contentStack.addArrangedSubview(title)
        
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(spacer)
        
        value.setContentHuggingPriority(.required, for: .horizontal)
        if let btn = value as? UIButton {
            btn.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.4)
            btn.layer.cornerRadius = 8
            btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
            NSLayoutConstraint.activate([
                btn.widthAnchor.constraint(equalToConstant: 140),
                btn.heightAnchor.constraint(equalToConstant: 30)
            ])
        }
        contentStack.addArrangedSubview(value)
        
        let separator = UIView()
        separator.backgroundColor = .systemGray4
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        
        let rowStack = UIStackView(arrangedSubviews: [contentStack, separator])
        rowStack.axis = .vertical
        rowStack.spacing = 10
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        
        if isLast {
            separator.isHidden = true
        }
        
        return rowStack
    }
}

