//
//  CertificatesViewController.swift
//  Stepic
//
//  Created by Ostrenkiy on 12.04.17.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import Foundation

@available(*, deprecated, message: "Class to initialize certificates w/o storyboards logic")
final class CertificatesLegacyAssembly: Assembly {
    private let userID: User.IdType

    init(userID: User.IdType) {
        self.userID = userID
    }

    func makeModule() -> UIViewController {
        guard let certificatesVC = ControllerHelper.instantiateViewController(
            identifier: "CertificatesViewController",
            storyboardName: "CertificatesStoryboard"
        ) as? CertificatesViewController else {
            fatalError("Unable to initialize CertificatesViewController via storyboard")
        }

        certificatesVC.userID = self.userID
        certificatesVC.presenter = CertificatesPresenter(
            userID: self.userID,
            certificatesAPI: ApiDataDownloader.certificates,
            coursesAPI: ApiDataDownloader.courses,
            presentationContainer: PresentationContainer.certificates,
            view: certificatesVC
        )

        return certificatesVC
    }
}

final class CertificatesViewController: UIViewController, ControllerWithStepikPlaceholder {
    var placeholderContainer = StepikPlaceholderControllerContainer()

    @IBOutlet weak var tableView: StepikTableView!

    private lazy var refreshControl = UIRefreshControl()
    private lazy var paginationView: LoadingPaginationView = {
        let paginationView = LoadingPaginationView()
        paginationView.refreshAction = { [weak self] in
            guard let presenter = self?.presenter else {
                return
            }

            if presenter.getNextPage() {
                self?.paginationView.setLoading()
            }
        }
        paginationView.setLoading()
        return paginationView
    }()

    var presenter: CertificatesPresenter?
    var userID: User.IdType?

    private var certificates: [CertificateViewData] = []
    private var showNextPageFooter = false

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        let isMe = AuthInfo.shared.userId != nil && self.userID == AuthInfo.shared.userId
        if isMe {
            self.tableView.emptySetPlaceholder = StepikPlaceholder(.emptyCertificatesMe) { [weak self] in
                self?.tabBarController?.selectedIndex = 1
            }
        } else {
            self.tableView.emptySetPlaceholder = StepikPlaceholder(.emptyCertificatesOther)
        }
        self.tableView.loadingPlaceholder = StepikPlaceholder(.emptyCertificatesLoading)

        registerPlaceholder(placeholder: StepikPlaceholder(.noConnection, action: { [weak self] in
            self?.presenter?.refreshCertificates()
        }), for: .connectionError)

        title = NSLocalizedString("Certificates", comment: "")

        tableView.register(
            UINib(nibName: "CertificateTableViewCell", bundle: nil),
            forCellReuseIdentifier: "CertificateTableViewCell"
        )

        self.tableView.estimatedRowHeight = 161
        self.tableView.rowHeight = UITableView.automaticDimension

        refreshControl.addTarget(
            self,
            action: #selector(CertificatesViewController.refreshCertificates),
            for: .valueChanged
        )
        tableView.refreshControl = refreshControl
        refreshControl.layoutIfNeeded()
        refreshControl.beginRefreshing()

        presenter?.getCachedCertificates()
        presenter?.refreshCertificates()

        tableView.backgroundColor = .stepikGroupedBackground
        tableView.contentInsetAdjustmentBehavior = .never

        DispatchQueue.main.async {
            self.displayRefreshing()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        StepikAnalytics.shared.send(.certificatesScreenOpened)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showProfile" {
            let dvc = segue.destination
            dvc.hidesBottomBarWhenPushed = true
        }
    }

    private func shareCertificate(certificate: CertificateViewData, button: UIButton) {
        guard let url = certificate.certificateURL else {
            return
        }

        StepikAnalytics.shared.send(
            .shareCertificateTapped(grade: certificate.grade, courseName: certificate.courseName ?? "")
        )

        DispatchQueue.global(qos: .background).async {
            let sharingViewController = SharingHelper.getSharingController(url.absoluteString)
            DispatchQueue.main.async {
                sharingViewController.popoverPresentationController?.sourceView = button
                self.present(sharingViewController, animated: true, completion: nil)
            }
        }
    }

    @objc
    private func refreshCertificates() {
        presenter?.refreshCertificates()
    }

    private func loadNextPage() {
        guard let presenter = presenter else {
            return
        }

        if presenter.getNextPage() {
            self.paginationView.setLoading()
        }
    }
}

extension CertificatesViewController: CertificatesView {
    func setCertificates(certificates: [CertificateViewData], hasNextPage: Bool) {
        self.certificates = certificates
        self.showNextPageFooter = hasNextPage

        CATransaction.begin()
        CATransaction.setCompletionBlock({
            [weak self] in
            self?.tableView.reloadData()
        })
        refreshControl.endRefreshing()
        CATransaction.commit()
    }

    func displayError() {
        refreshControl.endRefreshing()
        showPlaceholder(for: .connectionError)
    }

    func displayEmpty() {
        refreshControl.endRefreshing()
        tableView.reloadData()
        self.isPlaceholderShown = false
    }

    func displayRefreshing() {
        tableView.showLoadingPlaceholder()
        self.isPlaceholderShown = false
    }

    func displayLoadNextPageError() {
        self.paginationView.setError()
    }

    func updateData() {
        tableView.reloadData()
    }
}

extension CertificatesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard showNextPageFooter else {
            return UIView()
        }

        return paginationView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0.1 }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        self.showNextPageFooter ? 60.0 : 0.1
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool { true }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard certificates.count > indexPath.row else {
            return
        }

        guard let url = certificates[indexPath.row].certificateURL else {
            return
        }

        StepikAnalytics.shared.send(
            .certificateOpened(
                grade: certificates[indexPath.row].grade,
                courseName: certificates[indexPath.row].courseName ?? ""
            )
        )

        WebControllerManager.shared.presentWebControllerWithURL(
            url,
            inController: self,
            withKey: .certificate,
            allowsSafari: true,
            backButtonStyle: .close
        )
    }
}

extension CertificatesViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        self.certificates.isEmpty ? 0 : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { certificates.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard certificates.count > indexPath.row else {
            return UITableViewCell()
        }

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "CertificateTableViewCell",
            for: indexPath
        ) as? CertificateTableViewCell else {
            return UITableViewCell()
        }

        cell.initWith(certificateViewData: certificates[indexPath.row])

        cell.shareBlock = { [weak self] viewData, button in
            self?.shareCertificate(certificate: viewData, button: button)
        }

        if certificates.count == indexPath.row + 1 && showNextPageFooter {
            loadNextPage()
        }

        return cell
    }
}
